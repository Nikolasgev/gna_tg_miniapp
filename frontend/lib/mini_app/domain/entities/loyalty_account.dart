import 'package:equatable/equatable.dart';

class LoyaltyAccount extends Equatable {
  final String id;
  final String businessId;
  final int userTelegramId;
  final double pointsBalance;
  final double totalEarned;
  final double totalSpent;

  const LoyaltyAccount({
    required this.id,
    required this.businessId,
    required this.userTelegramId,
    required this.pointsBalance,
    required this.totalEarned,
    required this.totalSpent,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        userTelegramId,
        pointsBalance,
        totalEarned,
        totalSpent,
      ];
}

class LoyaltyTransaction extends Equatable {
  final String id;
  final String? orderId;
  final String transactionType;  // "earned" или "spent"
  final double points;
  final double balanceAfter;
  final String? description;
  final DateTime createdAt;

  const LoyaltyTransaction({
    required this.id,
    this.orderId,
    required this.transactionType,
    required this.points,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        orderId,
        transactionType,
        points,
        balanceAfter,
        description,
        createdAt,
      ];
}

