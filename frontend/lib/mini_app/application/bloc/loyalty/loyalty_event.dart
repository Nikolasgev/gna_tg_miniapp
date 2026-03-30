part of 'loyalty_bloc.dart';

abstract class LoyaltyEvent extends Equatable {
  const LoyaltyEvent();

  @override
  List<Object?> get props => [];
}

class LoadLoyaltyAccount extends LoyaltyEvent {
  final String businessSlug;
  final int userTelegramId;

  const LoadLoyaltyAccount({
    required this.businessSlug,
    required this.userTelegramId,
  });

  @override
  List<Object?> get props => [businessSlug, userTelegramId];
}

class LoadLoyaltyAccountDetail extends LoyaltyEvent {
  final String businessSlug;
  final int userTelegramId;
  final int limit;
  final int offset;

  const LoadLoyaltyAccountDetail({
    required this.businessSlug,
    required this.userTelegramId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [businessSlug, userTelegramId, limit, offset];
}

