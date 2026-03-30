import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Упрощенный логгер (минимум логирования)
final appLogger = Logger(
  printer: SimplePrinter(
    colors: false,
    printTime: false,
  ),
  level: kDebugMode ? Level.warning : Level.error, // В production только error, в debug warning и error
);

/// Получить логгер
Logger get logger {
  return appLogger;
}

/// Вспомогательная функция для безопасного логирования ошибок без показа пользователю
void logError(String message, {Object? error, StackTrace? stackTrace}) {
  if (kDebugMode) {
    logger.e(message, error: error, stackTrace: stackTrace);
  }
}
