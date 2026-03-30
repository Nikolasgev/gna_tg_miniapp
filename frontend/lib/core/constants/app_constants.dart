class AppConstants {
  // Storage keys
  static const String cartStorageKey = 'cart';
  static const String catalogCacheKey = 'catalog_cache';
  static const String userStorageKey = 'user';
  static const String configStorageKey = 'business_config';
  static const String authTokenKey = 'auth_token';
  
  // Cache TTL
  static const Duration catalogCacheTTL = Duration(seconds: 30);
  static const Duration configCacheTTL = Duration(minutes: 1);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Polling intervals
  static const Duration orderStatusPollInterval = Duration(seconds: 3);
  static const int maxOrderStatusPollAttempts = 20;
  
  // Network
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Locale
  static const String defaultLocale = 'ru_RU';
}

