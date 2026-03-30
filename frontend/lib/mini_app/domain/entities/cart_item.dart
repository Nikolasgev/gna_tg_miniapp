import 'package:equatable/equatable.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';

class CartItem extends Equatable {
  final String productId;
  final Product product;
  final int quantity;
  final String? note;
  final Map<String, String>? selectedVariations;  // Выбранные вариации (ключ -> значение)

  const CartItem({
    required this.productId,
    required this.product,
    required this.quantity,
    this.note,
    this.selectedVariations,
  });

  double get totalPrice {
    double basePrice = product.currentPrice;
    
    // Добавляем цены выбранных вариаций
    if (product.variations != null && selectedVariations != null) {
      final variations = product.variations as Map<String, dynamic>;
      for (final entry in selectedVariations!.entries) {
        final varKey = entry.key;
        final varValue = entry.value;
        
        if (variations.containsKey(varKey)) {
          final varData = variations[varKey];
          // Если вариация - объект с ценами {значение: цена}
          if (varData is Map && varData.containsKey(varValue)) {
            final variationPrice = varData[varValue];
            if (variationPrice is num) {
              basePrice += variationPrice.toDouble();
            }
          }
        }
      }
    }
    
    return basePrice * quantity;
  }

  CartItem copyWith({
    String? productId,
    Product? product,
    int? quantity,
    String? note,
    Map<String, String>? selectedVariations,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      selectedVariations: selectedVariations ?? this.selectedVariations,
    );
  }

  @override
  List<Object?> get props => [productId, product, quantity, note, selectedVariations];
}

