import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dartz/dartz.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/domain/entities/loyalty_account.dart';
import 'package:tg_store/mini_app/domain/repositories/loyalty_repository.dart';
import 'package:tg_store/core/error/failures.dart';

part 'loyalty_event.dart';
part 'loyalty_state.dart';

class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final LoyaltyRepository loyaltyRepository;

  LoyaltyBloc({required this.loyaltyRepository}) : super(LoyaltyInitial()) {
    on<LoadLoyaltyAccount>(_onLoadLoyaltyAccount);
    on<LoadLoyaltyAccountDetail>(_onLoadLoyaltyAccountDetail);
  }

  Future<void> _onLoadLoyaltyAccount(
    LoadLoyaltyAccount event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(LoyaltyLoading());

    final result = await loyaltyRepository.getAccount(
      businessSlug: event.businessSlug,
      userTelegramId: event.userTelegramId,
    );

    result.fold(
      (failure) {
        logger.e('Error loading loyalty account: ${failure.message}');
        emit(LoyaltyError(failure.message));
      },
      (account) {
        logger.i('✅ Loyalty account loaded: ${account.pointsBalance} points');
        emit(LoyaltyAccountLoaded(account));
      },
    );
  }

  Future<void> _onLoadLoyaltyAccountDetail(
    LoadLoyaltyAccountDetail event,
    Emitter<LoyaltyState> emit,
  ) async {
    emit(LoyaltyLoading());

    final result = await loyaltyRepository.getAccountDetail(
      businessSlug: event.businessSlug,
      userTelegramId: event.userTelegramId,
      limit: event.limit,
      offset: event.offset,
    );

    result.fold(
      (failure) {
        logger.e('Error loading loyalty account detail: ${failure.message}');
        emit(LoyaltyError(failure.message));
      },
      (data) {
        final accountData = data['account'] as Map<String, dynamic>;
        final transactionsData = data['transactions'] as List<dynamic>;

        final account = LoyaltyAccount(
          id: accountData['id'] as String,
          businessId: accountData['business_id'] as String,
          userTelegramId: accountData['user_telegram_id'] as int,
          pointsBalance: (accountData['points_balance'] as num).toDouble(),
          totalEarned: (accountData['total_earned'] as num).toDouble(),
          totalSpent: (accountData['total_spent'] as num).toDouble(),
        );

        final transactions = transactionsData.map((t) {
          return LoyaltyTransaction(
            id: t['id'] as String,
            orderId: t['order_id'] as String?,
            transactionType: t['transaction_type'] as String,
            points: (t['points'] as num).toDouble(),
            balanceAfter: (t['balance_after'] as num).toDouble(),
            description: t['description'] as String?,
            createdAt: DateTime.parse(t['created_at'] as String),
          );
        }).toList();

        logger.i('✅ Loyalty account detail loaded: ${account.pointsBalance} points, ${transactions.length} transactions');
        emit(LoyaltyAccountDetailLoaded(
          account: account,
          transactions: transactions,
        ));
      },
    );
  }
}

