part of 'orders_bloc.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<entities.Order> orders;
  final entities.Order? selectedOrder;

  const OrdersLoaded(this.orders, {this.selectedOrder});

  @override
  List<Object?> get props => [orders, selectedOrder];
}

class OrdersError extends OrdersState {
  final String message;

  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

