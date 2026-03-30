import 'package:shared_preferences/shared_preferences.dart';

class BusinessService {
  static const String _businessSlugKey = 'business_slug';
  static String? _cachedSlug;

  /// Получить business slug
  static Future<String?> getBusinessSlug() async {
    if (_cachedSlug != null) {
      return _cachedSlug;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedSlug = prefs.getString(_businessSlugKey);
      return _cachedSlug;
    } catch (e) {
      return null;
    }
  }

  /// Сохранить business slug
  static Future<void> setBusinessSlug(String slug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_businessSlugKey, slug);
      _cachedSlug = slug;
    } catch (e) {
      // Ignore errors
    }
  }

  /// Очистить business slug
  static Future<void> clearBusinessSlug() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_businessSlugKey);
      _cachedSlug = null;
    } catch (e) {
      // Ignore errors
    }
  }

  /// Получить business slug синхронно (из кэша)
  static String? getBusinessSlugSync() {
    return _cachedSlug;
  }
}

