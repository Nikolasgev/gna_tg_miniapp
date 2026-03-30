part of 'orders_bloc.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersEvent {
  final int? telegramId;
  final int page;
  final int limit;

  const LoadOrders({
    this.telegramId,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [telegramId, page, limit];
}

class RefreshOrders extends OrdersEvent {
  final int? telegramId;

  const RefreshOrders({this.telegramId});

  @override
  List<Object?> get props => [telegramId];
}

class LoadOrderDetails extends OrdersEvent {
  final String orderId;

  const LoadOrderDetails(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CancelOrder extends OrdersEvent {
  final String orderId;

  const CancelOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

