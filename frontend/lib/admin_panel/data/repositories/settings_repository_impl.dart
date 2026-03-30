import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/admin_panel/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSettings({
    required String businessSlug,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.businessSettings(businessSlug),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }

      return Left(ServerFailure('Ошибка загрузки настроек: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка загрузки настроек',
        error: e,
      );
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('Не удалось подключиться к серверу'));
      }
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Бизнес не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки настроек: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка загрузки настроек',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка загрузки настроек: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateSettings({
    required String businessSlug,
    required Map<String, dynamic> settingsData,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.businessSettings(businessSlug),
        data: settingsData,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      }

      return Left(ServerFailure('Ошибка обновления настроек: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка обновления настроек',
        error: e,
      );
      if (e.response?.statusCode == 404) {
        return Left(const NotFoundFailure('Бизнес не найден'));
      }
      return Left(ServerFailure('Ошибка обновления настроек: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка обновления настроек',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка обновления настроек: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage({
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          Uint8List.fromList(imageBytes),
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        ApiConstants.uploadImage,
        data: formData,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final imageUrl = data['url'] as String;
        
        // Преобразуем относительный URL в абсолютный
        final baseUrl = _apiClient.dio.options.baseUrl;
        if (imageUrl.startsWith('/')) {
          return Right('$baseUrl$imageUrl');
        }
        return Right(imageUrl);
      }

      return Left(ServerFailure('Ошибка загрузки изображения: ${response.statusCode}'));
    } on DioException catch (e) {
      logger.e(
        'Ошибка загрузки изображения',
        error: e,
      );
      return Left(ServerFailure('Ошибка загрузки изображения: ${e.message ?? e.toString()}'));
    } catch (e, stackTrace) {
      logger.e(
        'Неожиданная ошибка загрузки изображения',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Ошибка загрузки изображения: $e'));
    }
  }
}

