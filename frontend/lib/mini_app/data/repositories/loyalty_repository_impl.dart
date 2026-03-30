import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/mini_app/domain/entities/loyalty_account.dart';
import 'package:tg_store/mini_app/domain/repositories/loyalty_repository.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<Either<Failure, LoyaltyAccount>> getAccount({
    required String businessSlug,
    required int userTelegramId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.loyaltyAccountBySlug(businessSlug),
        queryParameters: {
          'user_telegram_id': userTelegramId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final account = LoyaltyAccount(
          id: data['id'] as String,
          businessId: data['business_id'] as String,
          userTelegramId: data['user_telegram_id'] as int,
          pointsBalance: (data['points_balance'] as num).toDouble(),
          totalEarned: (data['total_earned'] as num).toDouble(),
          totalSpent: (data['total_spent'] as num).toDouble(),
        );
        return Right(account);
      } else {
        return Left(ServerFailure('Failed to get loyalty account: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      return Left(ServerFailure('Error getting loyalty account: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAccountDetail({
    required String businessSlug,
    required int userTelegramId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Сначала получаем business_id через business_slug
      final businessResponse = await _apiClient.dio.get(
        ApiConstants.businessBySlug(businessSlug),
      );

      if (businessResponse.statusCode != 200) {
        return Left(ServerFailure('Failed to get business: ${businessResponse.statusCode}'));
      }

      final businessData = businessResponse.data;
      final businessId = businessData['id'] as String;

      final response = await _apiClient.dio.get(
        ApiConstants.loyaltyAccountDetail(businessId, userTelegramId),
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200) {
        return Right(response.data as Map<String, dynamic>);
      } else {
        return Left(ServerFailure('Failed to get loyalty account detail: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      return Left(ServerFailure('Error getting loyalty account detail: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

