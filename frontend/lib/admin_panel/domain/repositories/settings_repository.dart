import 'package:dartz/dartz.dart';
import 'package:tg_store/core/error/failures.dart';

/// Интерфейс репозитория для работы с настройками бизнеса в админ-панели
abstract class SettingsRepository {
  /// Получить настройки бизнеса
  Future<Either<Failure, Map<String, dynamic>>> getSettings({
    required String businessSlug,
  });

  /// Обновить настройки бизнеса
  Future<Either<Failure, Map<String, dynamic>>> updateSettings({
    required String businessSlug,
    required Map<String, dynamic> settingsData,
  });

  /// Загрузить изображение
  Future<Either<Failure, String>> uploadImage({
    required List<int> imageBytes,
    required String fileName,
  });
}

