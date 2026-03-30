import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/domain/entities/order.dart' as entities;
import 'package:tg_store/mini_app/domain/repositories/order_repository.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository orderRepository;

  OrdersBloc({required this.orderRepository}) : super(OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<RefreshOrders>(_onRefreshOrders);
    on<LoadOrderDetails>(_onLoadOrderDetails);
    on<CancelOrder>(_onCancelOrder);
  }

  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersState> emit,
  ) async {
    logger.i('LoadOrders event received, telegramId: ${event.telegramId}');
    emit(OrdersLoading());
    
    try {
      if (event.telegramId == null) {
        logger.e('Telegram ID is null');
        emit(OrdersError('Не удалось определить пользователя'));
        return;
      }

      logger.i('Requesting orders for telegramId: ${event.telegramId}');
      final result = await orderRepository.getOrders(
        telegramId: event.telegramId!,
        page: event.page,
        limit: event.limit,
      );
      
      result.fold(
        (failure) {
          logger.e('Error loading orders: ${failure.message}');
          emit(OrdersError('Ошибка при загрузке заказов: ${failure.message}'));
        },
        (orders) {
          logger.i('Orders loaded: ${orders.length} items');
          if (orders.isNotEmpty) {
            logger.i('First order userTelegramId: ${orders.first.userTelegramId}');
          }
          emit(OrdersLoaded(orders));
        },
      );
    } catch (e) {
      logger.e('Error loading orders');
      emit(OrdersError('Ошибка при загрузке заказов: $e'));
    }
  }

  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrdersState> emit,
  ) async {
    logger.i('RefreshOrders event received');
    add(LoadOrders(telegramId: event.telegramId));
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetails event,
    Emitter<OrdersState> emit,
  ) async {
    logger.i('LoadOrderDetails event: orderId=${event.orderId}');
    
    // Сохраняем текущий список заказов, если он есть
    final currentOrders = state is OrdersLoaded ? (state as OrdersLoaded).orders : <entities.Order>[];
    
    emit(OrdersLoading());
    
    try {
      final result = await orderRepository.getOrder(event.orderId);
      
      result.fold(
        (failure) {
          logger.e('Error loading order details: ${failure.message}');
          // Восстанавливаем предыдущее состояние с ошибкой
          if (currentOrders.isNotEmpty) {
            emit(OrdersLoaded(currentOrders));
          } else {
            emit(OrdersError('Ошибка при загрузке заказа: ${failure.message}'));
          }
        },
        (order) {
          logger.i('Order details loaded: ${order.id}');
          emit(OrdersLoaded(currentOrders, selectedOrder: order));
        },
      );
    } catch (e) {
      logger.e('Error loading order details');
      // Восстанавливаем предыдущее состояние с ошибкой
      if (currentOrders.isNotEmpty) {
        emit(OrdersLoaded(currentOrders));
      } else {
        emit(OrdersError('Ошибка при загрузке заказа: $e'));
      }
    }
  }

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrdersState> emit,
  ) async {
    logger.i('CancelOrder event: orderId=${event.orderId}');
    
    // Сохраняем текущий список заказов и telegramId для перезагрузки
    final currentOrders = state is OrdersLoaded ? (state as OrdersLoaded).orders : <entities.Order>[];
    int? telegramId;
    if (currentOrders.isNotEmpty && currentOrders.first.userTelegramId != null) {
      telegramId = currentOrders.first.userTelegramId;
    }
    
    emit(OrdersLoading());
    
    try {
      final result = await orderRepository.cancelOrder(event.orderId);
      
      result.fold(
        (failure) {
          logger.e('Error canceling order: ${failure.message}');
          // Восстанавливаем предыдущее состояние с ошибкой
          if (currentOrders.isNotEmpty) {
            emit(OrdersLoaded(currentOrders));
          } else {
            emit(OrdersError('Ошибка при отмене заказа: ${failure.message}'));
          }
        },
        (cancelledOrder) {
          logger.i('Order cancelled: ${cancelledOrder.id}');
          // Перезагружаем список заказов для получения актуальных данных
          if (telegramId != null) {
            add(LoadOrders(telegramId: telegramId));
          } else {
            // Если нет telegramId, обновляем заказ в текущем списке
            final updatedOrders = currentOrders.map((order) {
              if (order.id == cancelledOrder.id) {
                return cancelledOrder;
              }
              return order;
            }).toList();
            emit(OrdersLoaded(updatedOrders));
          }
        },
      );
    } catch (e) {
      logger.e('Error canceling order');
      // Восстанавливаем предыдущее состояние с ошибкой
      if (currentOrders.isNotEmpty) {
        emit(OrdersLoaded(currentOrders));
      } else {
        emit(OrdersError('Ошибка при отмене заказа: $e'));
      }
    }
  }
}

