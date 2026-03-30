part of 'orders_bloc.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Map<String, dynamic>> orders;

  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

// Состояния для работы с одним заказом
class OrderLoading extends OrdersState {}

class OrderLoaded extends OrdersState {
  final Map<String, dynamic> order;

  const OrderLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderUpdating extends OrdersState {}

class OrderUpdated extends OrdersState {
  final Map<String, dynamic> order;

  const OrderUpdated(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderError extends OrdersState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

