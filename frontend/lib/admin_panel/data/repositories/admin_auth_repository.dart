import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/network/api_client.dart';

class AdminAuthRepository {
  final ApiClient _apiClient;
  static const String _tokenKey = 'admin_access_token';
  static const String _businessSlugKey = 'admin_business_slug';
  static const String _businessNameKey = 'admin_business_name';

  AdminAuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Авторизация владельца бизнеса
  /// Возвращает true если авторизация успешна, false если неверный логин/пароль
  /// Выбрасывает исключение при ошибке сети
  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.adminLogin,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['ok'] == true) {
          // Сохраняем токен и информацию о бизнесе
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, data['access_token'] ?? '');
          await prefs.setString(_businessSlugKey, data['business_slug'] ?? '');
          await prefs.setString(_businessNameKey, data['business_name'] ?? '');
          
          // Устанавливаем токен в API клиент
          await _apiClient.setAuthToken(data['access_token']);
          
          return true;
        }
      }

      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Неверный логин или пароль
        return false;
      }
      // Другая ошибка сети
      rethrow;
    }
  }

  /// Получить сохраненный токен
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Получить slug бизнеса
  Future<String?> getBusinessSlug() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_businessSlugKey);
  }

  /// Получить название бизнеса
  Future<String?> getBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_businessNameKey);
  }

  /// Выход из системы
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_businessSlugKey);
    await prefs.remove(_businessNameKey);
    await _apiClient.clearAuthToken();
  }

  /// Проверка, авторизован ли пользователь
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

