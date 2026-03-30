enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  static Environment _environment = Environment.development;
  static String _baseUrl = '';

  static Environment get environment => _environment;
  static String get baseUrl => _baseUrl;

  /// Мок Telegram User ID для режима разработки/профилирования
  /// Можно переопределить через переменную окружения MOCK_TELEGRAM_ID
  static int get mockTelegramId {
    const mockIdFromEnv = String.fromEnvironment('MOCK_TELEGRAM_ID', defaultValue: '');
    if (mockIdFromEnv.isNotEmpty) {
      try {
        return int.parse(mockIdFromEnv);
      } catch (e) {
        // Если не удалось распарсить, используем значение по умолчанию
      }
    }
    // Значение по умолчанию для разработки
    return 123456789;
  }

  static void setEnvironment(Environment env) {
    _environment = env;
    switch (env) {
      case Environment.development:
        // Для Telegram WebView нужно использовать IP-адрес вместо localhost
        // Можно переопределить через переменную окружения API_BASE_URL
        final apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
        if (apiBaseUrl.isNotEmpty) {
          _baseUrl = apiBaseUrl;
        } else {
          // По умолчанию используем IP-адрес для Telegram WebView (localhost не работает)
          // Для изменения IP-адреса используйте: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8000
          // Или установите переменную окружения API_BASE_URL
          _baseUrl = 'http://192.168.50.68:8000';
        }
        break;
      case Environment.staging:
        _baseUrl = 'https://api-staging.example.com';
        break;
      case Environment.production:
        // Можно переопределить через переменную окружения API_BASE_URL
        // SAME_ORIGIN = запросы на тот же origin (для ngrok, когда frontend раздаётся с backend)
        final apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
        if (apiBaseUrl == 'SAME_ORIGIN') {
          _baseUrl = '';
        } else if (apiBaseUrl.isNotEmpty) {
          _baseUrl = apiBaseUrl;
        } else {
          _baseUrl = 'https://gnatgminiapp-production.up.railway.app';
        }
        break;
    }
  }

  static bool get isDevelopment => _environment == Environment.development;
  static bool get isProduction => _environment == Environment.production;
}

