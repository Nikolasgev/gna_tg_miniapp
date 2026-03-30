import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/mini_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<Either<Failure, TelegramUser>> validateInitData({
    required String initData,
    required String businessSlug,
  }) async {
    // Проверяем, что initData не пустой
    if (initData.isEmpty || initData.trim().isEmpty) {
      return Left(ServerFailure('init_data пустой или не предоставлен'));
    }

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.validateInitData,
        data: {
          'init_data': initData,
        },
      );

      if (response.statusCode == 200 && response.data['ok'] == true) {
        final userData = response.data['telegram_user'];
        if (userData != null) {
          final user = TelegramUser(
            id: userData['id'] as int,
            firstName: userData['first_name'] as String? ?? '',
            lastName: userData['last_name'] as String?,
            username: userData['username'] as String?,
            phoneNumber: null, // Telegram не передает phone в init_data
            languageCode: userData['language_code'] as String?,
          );
          return Right(user);
        }
      }

      return Left(ServerFailure('Неверный формат ответа от сервера'));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return Left(ServerFailure('Не удалось подключиться к серверу. Проверьте, что бэкенд запущен на ${_apiClient.dio.options.baseUrl}'));
      }
      if (e.response?.statusCode == 401) {
        return Left(ServerFailure('Неверная подпись init_data'));
      }
      if (e.response?.statusCode == 400) {
        final detail = e.response?.data['detail'] as String?;
        return Left(ServerFailure(detail ?? 'Неверный запрос'));
      }
      return Left(ServerFailure('Ошибка валидации: ${e.message ?? e.toString()}'));
    } catch (e) {
      return Left(ServerFailure('Ошибка валидации: $e'));
    }
  }
}

