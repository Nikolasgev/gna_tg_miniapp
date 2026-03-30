part of 'cart_bloc.dart';

abstract class CartState extends Equatable {
  const CartState();

  List<CartItem> get items => [];

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  List<Object> get props => [];
}

class CartInitial extends CartState {}

class CartLoaded extends CartState {
  @override
  final List<CartItem> items;

  const CartLoaded(this.items);

  @override
  List<Object> get props => [items];
}

