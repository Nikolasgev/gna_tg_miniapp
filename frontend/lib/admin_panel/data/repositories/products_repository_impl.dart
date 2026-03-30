import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/admin_panel/domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ApiClient _apiClient;

  ProductsRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getProducts({
    required String businessSlug,
    String? searchQuery,
    String? categoryId,
    bool? includeInactive,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        '_t': DateTime.now().millisecondsSinceEpoch,
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }

      if (categoryId != null) {
        queryParams['category'] = categoryId;
      }

      if (includeInactive == true) {
        queryParams['include_inactive'] = true;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.adminProducts(businessSlug),
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return Right(data.cast<Map<String, dynamic>>());
      }

      return Left(ServerFailure('Ошибка загрузки товаров: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e('Ошибка загрузки товаров', error: e);
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('Не удалось подключиться к серверу'));
      }
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Бизнес не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки товаров: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка загрузки товаров',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка загрузки товаров: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProduct({
    required String businessSlug,
    required String productId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.adminProduct(productId),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        return Left(const NotFoundFailure('Товар не найден'));
      }

      return Left(ServerFailure('Ошибка загрузки товара: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка загрузки товара',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Товар не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки товара: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка загрузки товара',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка загрузки товара: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createProduct({
    required String businessSlug,
    required Map<String, dynamic> productData,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminProducts(businessSlug),
        data: productData,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(response.data as Map<String, dynamic>);
      }

      return Left(ServerFailure('Ошибка создания товара: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка создания товара',
        error: e,
      );
      return Left(ServerFailure('Ошибка создания товара: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка создания товара',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка создания товара: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateProduct({
    required String businessSlug,
    required String productId,
    required Map<String, dynamic> productData,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.adminProduct(productId),
        data: productData,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        return Left(const NotFoundFailure('Товар не найден'));
      }

      return Left(ServerFailure('Ошибка обновления товара: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка обновления товара',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Товар не найден'));
      }
      return Left(ServerFailure('Ошибка обновления товара: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка обновления товара',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка обновления товара: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct({
    required String businessSlug,
    required String productId,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiConstants.adminProduct(productId),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return const Right(null);
      }

      if (response.statusCode == 404) {
        return Left(const NotFoundFailure('Товар не найден'));
      }

      return Left(ServerFailure('Ошибка удаления товара: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка удаления товара',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Товар не найден'));
      }
      return Left(ServerFailure('Ошибка удаления товара: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка удаления товара',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка удаления товара: $e'));
    }
  }
}

