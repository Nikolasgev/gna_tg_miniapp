import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/services/business_service.dart';
import 'package:tg_store/core/theme/business_theme.dart';
import 'package:tg_store/core/utils/logger.dart';

class BusinessThemeService {
  final ApiClient _apiClient = ApiClient();
  BusinessTheme? _cachedTheme;
  String? _cachedBusinessSlug;

  /// Загрузить тему бизнеса с бекенда
  Future<BusinessTheme> loadBusinessTheme() async {
    try {
      final businessSlug = await BusinessService.getBusinessSlug();
      
      if (businessSlug == null || businessSlug.isEmpty) {
        logger.w('Business slug is not set, returning empty theme');
        return BusinessTheme.empty();
      }

      // Используем кэш, если slug не изменился
      if (_cachedTheme != null && _cachedBusinessSlug == businessSlug) {
        logger.d('Using cached theme for business: $businessSlug');
        return _cachedTheme!;
      }

      logger.i('Loading theme for business: $businessSlug');
      
      final response = await _apiClient.dio.get(
        ApiConstants.businessSettings(businessSlug),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final theme = BusinessTheme.fromJson(data);
        
        // Кэшируем тему
        _cachedTheme = theme;
        _cachedBusinessSlug = businessSlug;
        
        logger.i('Theme loaded successfully. Has custom colors: ${theme.hasCustomColors}');
        return theme;
      } else {
        logger.w('Failed to load theme, status code: ${response.statusCode}');
        return BusinessTheme.empty();
      }
    } catch (e, stackTrace) {
      logger.e('Error loading business theme', error: e, stackTrace: stackTrace);
      return BusinessTheme.empty();
    }
  }

  /// Очистить кэш темы
  void clearCache() {
    _cachedTheme = null;
    _cachedBusinessSlug = null;
    logger.d('Business theme cache cleared');
  }

  /// Получить кэшированную тему
  BusinessTheme? getCachedTheme() {
    return _cachedTheme;
  }
}




