import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/admin_panel/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<Map<String, dynamic>> getAnalyticsSummary({
    required String businessSlug,
    String? startDate,
    String? endDate,
  }) async {
    // Сначала получаем business_id через business_slug
    final businessResponse = await _apiClient.dio.get(
      ApiConstants.businessBySlug(businessSlug),
    );

    if (businessResponse.statusCode != 200) {
      throw Exception('Failed to get business: ${businessResponse.statusCode}');
    }

    final businessData = businessResponse.data;
    final businessId = businessData['id'] as String;

    // Получаем аналитику
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate;
    }

    final response = await _apiClient.dio.get(
      ApiConstants.analyticsSummary(businessId),
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get analytics: ${response.statusCode}');
    }
  }
}

