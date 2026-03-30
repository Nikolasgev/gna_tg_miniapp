abstract class AnalyticsRepository {
  Future<Map<String, dynamic>> getAnalyticsSummary({
    required String businessSlug,
    String? startDate,
    String? endDate,
  });
}

