import 'package:dartz/dartz.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/mini_app/domain/entities/loyalty_account.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, LoyaltyAccount>> getAccount({
    required String businessSlug,
    required int userTelegramId,
  });
  
  Future<Either<Failure, Map<String, dynamic>>> getAccountDetail({
    required String businessSlug,
    required int userTelegramId,
    int limit = 50,
    int offset = 0,
  });
}

