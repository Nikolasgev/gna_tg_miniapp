import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/utils/logger.dart' show logger;
import 'package:tg_store/core/utils/telegram_webapp.dart';

class ApiClient {
  late final Dio _dio;
  String? _authToken;
  bool _tokenLoaded = false;
  static const String _tokenKey = 'admin_access_token';

  ApiClient() {
    final baseUrl = AppConfig.baseUrl;
    // Пустой baseUrl допустим для same-origin (Mini App раздаётся с backend, ngrok)
    if (baseUrl.isEmpty) {
      logger.i('ApiClient: same-origin mode (relative URLs)');
    } else {
      logger.i('ApiClient initializing with baseUrl: $baseUrl');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Загружаем токен при первом запросе, если еще не загружен
          if (!_tokenLoaded) {
            await _loadToken();
          }
          
          // Add auth token if available
          final token = _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          final initData = TelegramWebApp.getInitData();
          if (initData != null && initData.isNotEmpty) {
            options.headers['X-Telegram-Init-Data'] = initData;
          }
          
          // Log requests in development
          if (AppConfig.isDevelopment) {
            logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
            logger.d('Headers: ${options.headers}');
            if (options.data != null) {
              logger.d('Data: ${options.data}');
            }
          }
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (AppConfig.isDevelopment) {
            logger.d('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
            // Для 204 No Content ответа data может быть null
            if (response.statusCode == 204) {
              logger.d('Data: (No Content)');
            } else {
              logger.d('Data: ${response.data}');
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (AppConfig.isDevelopment) {
            logger.e('ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
            logger.e('Full URL: ${error.requestOptions.uri}');
            logger.e('Error type: ${error.type}');
            logger.e('Message: ${error.message}');
            if (error.response != null) {
              logger.e('Response data: ${error.response?.data}');
            }
            if (error.type == DioExceptionType.connectionError) {
              logger.w('Connection error - проверьте, что бэкенд запущен на ${error.requestOptions.baseUrl}');
              logger.w('   Попробуйте: cd backend && docker-compose up -d');
            }
          }
          
          // Handle 401/403 errors
          if (error.response?.statusCode == 401) {
            _handleUnauthorized();
          } else if (error.response?.statusCode == 403) {
            _handleForbidden();
          }
          
          handler.next(error);
        },
      ),
    );
    
    // Загружаем токен из хранилища при инициализации
    _loadToken();
  }

  Dio get dio => _dio;

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        _authToken = token;
      }
    } catch (e) {
      // Игнорируем ошибки загрузки токена
    }
  }

  String? _getAuthToken() {
    return _authToken;
  }

  /// Установить токен авторизации
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      // Игнорируем ошибки сохранения токена
    }
  }

  /// Очистить токен авторизации
  Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      // Игнорируем ошибки удаления токена
    }
  }

  void _handleUnauthorized() {
    // Очищаем токен при 401 ошибке
    clearAuthToken();
  }

  void _handleForbidden() {
    // Обработка 403 ошибки
  }
}

