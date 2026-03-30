import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tg_store/core/utils/logger.dart';

class ThemeService {
  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  /// Получить сохраненный ThemeMode
  static Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);
      
      if (themeModeString == null) {
        return ThemeMode.dark; // По умолчанию темная тема
      }
      
      switch (themeModeString) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
          return ThemeMode.system;
        default:
          return ThemeMode.dark;
      }
    } catch (e, stackTrace) {
      logger.e('Error getting theme mode', error: e, stackTrace: stackTrace);
      return ThemeMode.dark;
    }
  }

  /// Сохранить ThemeMode
  static Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeModeString;
      
      switch (themeMode) {
        case ThemeMode.light:
          themeModeString = 'light';
          break;
        case ThemeMode.dark:
          themeModeString = 'dark';
          break;
        case ThemeMode.system:
          themeModeString = 'system';
          break;
      }
      
      await prefs.setString(_themeModeKey, themeModeString);
      logger.i('Theme mode saved: $themeModeString');
    } catch (e, stackTrace) {
      logger.e('Error saving theme mode', error: e, stackTrace: stackTrace);
    }
  }

  /// Получить сохраненную локаль
  static Future<Locale?> getLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = prefs.getString(_localeKey);
      
      if (localeString == null) {
        return null; // Использовать системную локаль
      }
      
      final parts = localeString.split('_');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      } else if (parts.length == 1) {
        return Locale(parts[0]);
      }
      
      return null;
    } catch (e, stackTrace) {
      logger.e('Error getting locale', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Сохранить локаль
  static Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = '${locale.languageCode}_${locale.countryCode ?? ''}';
      await prefs.setString(_localeKey, localeString);
      logger.i('Locale saved: $localeString');
    } catch (e, stackTrace) {
      logger.e('Error saving locale', error: e, stackTrace: stackTrace);
    }
  }
}

