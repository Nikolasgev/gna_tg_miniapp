part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final Product product;
  final int quantity;
  final String? note;
  final Map<String, String>? selectedVariations;  // Выбранные вариации

  const AddToCart({
    required this.product,
    this.quantity = 1,
    this.note,
    this.selectedVariations,
  });

  @override
  List<Object?> get props => [product, quantity, selectedVariations];
}

class RemoveFromCart extends CartEvent {
  final String productId;
  final Map<String, String>? selectedVariations;  // Вариации для идентификации товара

  const RemoveFromCart(
    this.productId, {
    this.selectedVariations,
  });

  @override
  List<Object?> get props => [productId, selectedVariations];
}

class UpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;
  final Map<String, String>? selectedVariations;  // Вариации для идентификации товара

  const UpdateQuantity({
    required this.productId,
    required this.quantity,
    this.selectedVariations,
  });

  @override
  List<Object?> get props => [productId, quantity, selectedVariations];
}

class ClearCart extends CartEvent {}

class LoadCart extends CartEvent {
  final List<CartItem> items;

  const LoadCart(this.items);

  @override
  List<Object> get props => [items];
}

class LoadCartFromStorage extends CartEvent {
  const LoadCartFromStorage();
}

