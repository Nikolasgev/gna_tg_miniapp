import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/utils/logger.dart' show logger;
import 'package:tg_store/mini_app/domain/entities/category.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';
import 'package:tg_store/mini_app/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final ApiClient _apiClient = ApiClient();

  CatalogRepositoryImpl() {
    // Проверяем baseUrl при создании
    logger.d('📡 CatalogRepositoryImpl created with baseUrl: ${AppConfig.baseUrl}');
  }

  @override
  Future<Either<Failure, List<Category>>> getCategories(String businessSlug) async {
    try {
      final url = ApiConstants.businessCategories(businessSlug);
      logger.d('🔍 Requesting categories from: $url');
      final response = await _apiClient.dio.get(
        url,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final categories = data.map((json) => Category(
          id: json['id'] as String,
          businessId: businessSlug, // Используем slug как идентификатор
          name: json['name'] as String,
          position: json['position'] as int? ?? 0,
          createdAt: DateTime.now(), // Бэкенд не возвращает, используем текущее время
          updatedAt: DateTime.now(),
        )).toList();

        return Right(categories);
      }

      return Left(ServerFailure('Неверный формат ответа от сервера'));
    } on DioException catch (e) {
      logger.d('❌ DioException in getCategories: ${e.type}, message: ${e.message}');
      logger.d('   Response: ${e.response?.statusCode}, data: ${e.response?.data}');
      logger.d('   Request path: ${e.requestOptions.path}');
      
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('Не удалось подключиться к серверу. Проверьте, что бэкенд запущен на ${_apiClient.dio.options.baseUrl}'));
      }
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Бизнес не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки категорий: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.d('❌ Exception in getCategories: $e');
      logger.d('   Stack: $stackTrace');
      return Left(ServerFailure('Ошибка загрузки категорий: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProducts({
    required String businessSlug,
    String? categoryId,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (categoryId != null) {
        queryParams['category'] = categoryId;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }

      if (minPrice != null) {
        queryParams['min_price'] = minPrice;
        logger.d('🔍 CatalogRepository: Adding min_price filter: $minPrice');
      }

      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice;
        logger.d('🔍 CatalogRepository: Adding max_price filter: $maxPrice');
      }

      final url = ApiConstants.businessProducts(businessSlug);
      logger.d('🔍 Requesting products from: $url');
      logger.d('🔍 Query params: $queryParams');
      final response = await _apiClient.dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
               final products = data.map((json) {
                 // Парсим поля скидок
                 double? discountPercentage;
                 if (json['discount_percentage'] != null) {
                   discountPercentage = (json['discount_percentage'] as num).toDouble();
                 }
                 
                 double? discountPrice;
                 if (json['discount_price'] != null) {
                   discountPrice = (json['discount_price'] as num).toDouble();
                 }
                 
                 DateTime? discountValidFrom;
                 if (json['discount_valid_from'] != null) {
                   discountValidFrom = DateTime.tryParse(json['discount_valid_from'] as String);
                 }
                 
                 DateTime? discountValidUntil;
                 if (json['discount_valid_until'] != null) {
                   discountValidUntil = DateTime.tryParse(json['discount_valid_until'] as String);
                 }
                 
                 int? stockQuantity;
                 if (json['stock_quantity'] != null) {
                   stockQuantity = json['stock_quantity'] as int;
                 }
                 
                 return Product(
                   id: json['id'] as String,
                   businessId: businessSlug,
                   title: json['title'] as String,
                   description: json['description'] as String?,
                   price: (json['price'] as num).toDouble(),
                   currency: json['currency'] as String? ?? 'RUB',
                   sku: json['sku'] as String?,
                   imageUrl: json['image_url'] as String?,
                   variations: json['variations'] != null 
                       ? Map<String, dynamic>.from(json['variations'] as Map)
                       : null,
                   isActive: json['is_active'] as bool? ?? true,
                   categoryIds: (json['category_ids'] as List<dynamic>?)
                       ?.map((id) => id.toString())
                       .toList() ?? [],
                   discountPercentage: discountPercentage,
                   discountPrice: discountPrice,
                   discountValidFrom: discountValidFrom,
                   discountValidUntil: discountValidUntil,
                   stockQuantity: stockQuantity,
                   createdAt: DateTime.now(),
                   updatedAt: DateTime.now(),
                 );
               }).toList();

        return Right(products);
      }

      return Left(ServerFailure('Неверный формат ответа от сервера'));
    } on DioException catch (e) {
      logger.d('❌ DioException in getProducts: ${e.type}, message: ${e.message}');
      logger.d('   Response: ${e.response?.statusCode}, data: ${e.response?.data}');
      logger.d('   Request path: ${e.requestOptions.path}');
      
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('Не удалось подключиться к серверу. Проверьте, что бэкенд запущен на ${_apiClient.dio.options.baseUrl}'));
      }
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Бизнес не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки продуктов: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.d('❌ Exception in getProducts: $e');
      logger.d('   Stack: $stackTrace');
      return Left(ServerFailure('Ошибка загрузки продуктов: $e'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProduct(String productId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.product(productId),
      );

      if (response.statusCode == 200) {
        final json = response.data;
        
        // Парсим поля скидок
        double? discountPercentage;
        if (json['discount_percentage'] != null) {
          discountPercentage = (json['discount_percentage'] as num).toDouble();
        }
        
        double? discountPrice;
        if (json['discount_price'] != null) {
          discountPrice = (json['discount_price'] as num).toDouble();
        }
        
        DateTime? discountValidFrom;
        if (json['discount_valid_from'] != null) {
          discountValidFrom = DateTime.tryParse(json['discount_valid_from'] as String);
        }
        
        DateTime? discountValidUntil;
        if (json['discount_valid_until'] != null) {
          discountValidUntil = DateTime.tryParse(json['discount_valid_until'] as String);
        }
        
        int? stockQuantity;
        if (json['stock_quantity'] != null) {
          stockQuantity = json['stock_quantity'] as int;
        }
        
        final product = Product(
          id: json['id'] as String,
          businessId: json['business_id'] as String? ?? '',
          title: json['title'] as String,
          description: json['description'] as String?,
          price: (json['price'] as num).toDouble(),
          currency: json['currency'] as String? ?? 'RUB',
          sku: json['sku'] as String?,
          imageUrl: json['image_url'] as String?,
          variations: json['variations'] != null 
              ? Map<String, dynamic>.from(json['variations'] as Map)
              : null,
          isActive: json['is_active'] as bool? ?? true,
          categoryIds: (json['category_ids'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ?? [],
          discountPercentage: discountPercentage,
          discountPrice: discountPrice,
          discountValidFrom: discountValidFrom,
          discountValidUntil: discountValidUntil,
          stockQuantity: stockQuantity,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return Right(product);
      }

      return Left(ServerFailure('Неверный формат ответа от сервера'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Продукт не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки продукта: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Ошибка загрузки продукта: $e'));
    }
  }
}

