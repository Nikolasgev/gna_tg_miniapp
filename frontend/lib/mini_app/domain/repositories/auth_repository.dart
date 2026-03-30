import 'package:dartz/dartz.dart';
import 'package:tg_store/core/error/failures.dart';

class TelegramUser {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? phoneNumber;
  final String? photoUrl;
  final String? languageCode;

  const TelegramUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.phoneNumber,
    this.photoUrl,
    this.languageCode,
  });
}

abstract class AuthRepository {
  Future<Either<Failure, TelegramUser>> validateInitData({
    required String initData,
    required String businessSlug,
  });
}

