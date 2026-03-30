part of 'loyalty_bloc.dart';

abstract class LoyaltyState extends Equatable {
  const LoyaltyState();

  @override
  List<Object?> get props => [];
}

class LoyaltyInitial extends LoyaltyState {}

class LoyaltyLoading extends LoyaltyState {}

class LoyaltyAccountLoaded extends LoyaltyState {
  final LoyaltyAccount account;

  const LoyaltyAccountLoaded(this.account);

  @override
  List<Object?> get props => [account];
}

class LoyaltyAccountDetailLoaded extends LoyaltyState {
  final LoyaltyAccount account;
  final List<LoyaltyTransaction> transactions;

  const LoyaltyAccountDetailLoaded({
    required this.account,
    required this.transactions,
  });

  @override
  List<Object?> get props => [account, transactions];
}

class LoyaltyError extends LoyaltyState {
  final String message;

  const LoyaltyError(this.message);

  @override
  List<Object?> get props => [message];
}

