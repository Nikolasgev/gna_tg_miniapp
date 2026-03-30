part of 'orders_bloc.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersEvent {
  final String businessSlug;
  final int page;
  final int limit;

  const LoadOrders(this.businessSlug, {this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [businessSlug, page, limit];
}

class LoadOrder extends OrdersEvent {
  final String businessSlug;
  final String orderId;

  const LoadOrder(this.businessSlug, this.orderId);

  @override
  List<Object?> get props => [businessSlug, orderId];
}

class UpdateOrderStatus extends OrdersEvent {
  final String businessSlug;
  final String orderId;
  final String status;
  final String? paymentStatus;

  const UpdateOrderStatus(
    this.businessSlug,
    this.orderId,
    this.status, {
    this.paymentStatus,
  });

  @override
  List<Object?> get props => [businessSlug, orderId, status, paymentStatus];
}

