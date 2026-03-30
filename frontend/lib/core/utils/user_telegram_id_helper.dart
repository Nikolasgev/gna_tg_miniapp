import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/core/utils/telegram_webapp.dart';
import 'package:tg_store/mini_app/application/bloc/auth/auth_bloc.dart';

/// Утилита для получения Telegram User ID с поддержкой мока в режиме разработки
class UserTelegramIdHelper {
  /// Мок Telegram ID для режима разработки/профилирования
  static int get _mockTelegramId => AppConfig.mockTelegramId;

  /// Получить Telegram User ID из различных источников
  /// 
  /// Приоритет:
  /// 1. Из AuthBloc (если пользователь аутентифицирован)
  /// 2. Из Telegram WebApp initDataUnsafe
  /// 3. Мок ID в режиме разработки (если включен)
  /// 
  /// Returns: Telegram User ID или null, если не удалось получить
  static int? getUserTelegramId({
    BuildContext? context,
    bool useMockInDevelopment = true,
  }) {
    // 1. Пытаемся получить из AuthBloc (если передан context)
    if (context != null) {
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          logger.d('✅ User Telegram ID from AuthBloc: ${authState.user.id}');
          return authState.user.id;
        }
      } catch (e) {
        logger.w('Failed to get user ID from AuthBloc: $e');
      }
    }

    // 2. Пытаемся получить из Telegram WebApp
    try {
      final initDataUnsafe = TelegramWebApp.getInitDataUnsafe();
      if (initDataUnsafe != null && initDataUnsafe['user'] != null) {
        final userData = initDataUnsafe['user'] as Map<String, dynamic>?;
        if (userData != null && userData['id'] != null) {
          final id = (userData['id'] as num).toInt();
          logger.d('✅ User Telegram ID from Telegram WebApp: $id');
          return id;
        }
      }
    } catch (e) {
      logger.w('Failed to get user ID from Telegram WebApp: $e');
    }

    // 3. В режиме разработки возвращаем мок ID
    if (useMockInDevelopment && AppConfig.isDevelopment) {
      logger.w('⚠️ Using mock Telegram ID for development: $_mockTelegramId');
      return _mockTelegramId;
    }

    logger.w('⚠️ Could not get Telegram User ID');
    return null;
  }

  /// Получить Telegram User ID или выбросить исключение, если не удалось
  /// 
  /// В режиме разработки использует мок ID, в production выбрасывает исключение
  static int getUserTelegramIdOrThrow({
    BuildContext? context,
    bool useMockInDevelopment = true,
  }) {
    final id = getUserTelegramId(
      context: context,
      useMockInDevelopment: useMockInDevelopment,
    );

    if (id != null) {
      return id;
    }

    if (useMockInDevelopment && AppConfig.isDevelopment) {
      logger.w('⚠️ Using mock Telegram ID (throw mode): $_mockTelegramId');
      return _mockTelegramId;
    }

    throw Exception('Telegram User ID is not available and mock is disabled');
  }
}
