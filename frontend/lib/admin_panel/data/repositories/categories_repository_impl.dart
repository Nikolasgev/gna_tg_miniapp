import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/admin_panel/domain/repositories/categories_repository.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final ApiClient _apiClient;

  CategoriesRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCategories({
    required String businessSlug,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.adminCategories(businessSlug),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return Right(data.cast<Map<String, dynamic>>());
      }

      return Left(ServerFailure('Ошибка загрузки категорий: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка загрузки категорий',
        error: e,
      );
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('Не удалось подключиться к серверу'));
      }
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Бизнес не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки категорий: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка загрузки категорий',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка загрузки категорий: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getCategory({
    required String businessSlug,
    required String categoryId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.adminCategory(categoryId),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        return Left(const NotFoundFailure('Категория не найдена'));
      }

      return Left(ServerFailure('Ошибка загрузки категории: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка загрузки категории',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Категория не найдена'));
      }
      return Left(ServerFailure('Ошибка загрузки категории: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка загрузки категории',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка загрузки категории: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createCategory({
    required String businessSlug,
    required Map<String, dynamic> categoryData,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminCategories(businessSlug),
        data: categoryData,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(response.data as Map<String, dynamic>);
      }

      return Left(ServerFailure('Ошибка создания категории: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка создания категории',
        error: e,
      );
      return Left(ServerFailure('Ошибка создания категории: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка создания категории',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка создания категории: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateCategory({
    required String businessSlug,
    required String categoryId,
    required Map<String, dynamic> categoryData,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.adminCategory(categoryId),
        data: categoryData,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        return Left(const NotFoundFailure('Категория не найдена'));
      }

      return Left(ServerFailure('Ошибка обновления категории: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка обновления категории',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Категория не найдена'));
      }
      return Left(ServerFailure('Ошибка обновления категории: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка обновления категории',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка обновления категории: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory({
    required String businessSlug,
    required String categoryId,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        ApiConstants.adminCategory(categoryId),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return const Right(null);
      }

      if (response.statusCode == 404) {
        return Left(const NotFoundFailure('Категория не найдена'));
      }

      return Left(ServerFailure('Ошибка удаления категории: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка удаления категории',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Категория не найдена'));
      }
      return Left(ServerFailure('Ошибка удаления категории: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка удаления категории',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка удаления категории: $e'));
    }
  }
}

