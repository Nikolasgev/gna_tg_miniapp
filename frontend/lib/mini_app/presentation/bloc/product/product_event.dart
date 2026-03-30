part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object> get props => [];
}

class LoadProduct extends ProductEvent {
  final String productId;

  const LoadProduct(this.productId);

  @override
  List<Object> get props => [productId];
}

class UpdateQuantity extends ProductEvent {
  final int quantity;

  const UpdateQuantity(this.quantity);

  @override
  List<Object> get props => [quantity];
}

class IncrementQuantity extends ProductEvent {
  const IncrementQuantity();
}

class DecrementQuantity extends ProductEvent {
  const DecrementQuantity();
}

