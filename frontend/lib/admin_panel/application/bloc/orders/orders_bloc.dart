import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/admin_panel/domain/repositories/orders_repository.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository ordersRepository;

  OrdersBloc({required this.ordersRepository}) : super(OrdersInitial()) {
    logger.i('OrdersBloc created');

    on<LoadOrders>(_onLoadOrders);
    on<LoadOrder>(_onLoadOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
  }

  void _onLoadOrders(LoadOrders event, Emitter<OrdersState> emit) async {
    logger.i('LoadOrders event: businessSlug=${event.businessSlug}');
    emit(OrdersLoading());

    final result = await ordersRepository.getOrders(
      businessSlug: event.businessSlug,
      page: event.page,
      limit: event.limit,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load orders: ${failure.message}');
        emit(OrdersError(failure.message));
      },
      (orders) {
        logger.i('Loaded ${orders.length} orders');
        emit(OrdersLoaded(orders));
      },
    );
  }

  void _onLoadOrder(LoadOrder event, Emitter<OrdersState> emit) async {
    logger.i('LoadOrder event: orderId=${event.orderId}');
    emit(OrderLoading());

    final result = await ordersRepository.getOrder(
      businessSlug: event.businessSlug,
      orderId: event.orderId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load order: ${failure.message}');
        emit(OrderError(failure.message));
      },
      (order) {
        logger.i('Order loaded: ${order['id']}');
        emit(OrderLoaded(order));
      },
    );
  }

  void _onUpdateOrderStatus(UpdateOrderStatus event, Emitter<OrdersState> emit) async {
    logger.i('UpdateOrderStatus event: orderId=${event.orderId}, status=${event.status}');
    emit(OrderUpdating());

    final result = await ordersRepository.updateOrderStatus(
      businessSlug: event.businessSlug,
      orderId: event.orderId,
      status: event.status,
      paymentStatus: event.paymentStatus,
    );

    result.fold(
      (failure) {
        logger.e('Failed to update order status: ${failure.message}');
        emit(OrderError(failure.message));
      },
      (order) {
        logger.i('Order status updated: ${order['id']}');
        emit(OrderUpdated(order));
        add(LoadOrders(event.businessSlug));
      },
    );
  }
}

