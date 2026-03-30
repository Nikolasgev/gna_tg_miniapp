import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/domain/entities/cart_item.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';

class CartStorageService {
  static const String _cartKey = 'cart_items';

  /// Сохраняет корзину в локальное хранилище
  Future<void> saveCart(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => _cartItemToJson(item)).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_cartKey, jsonString);
      logger.i('Cart saved: ${items.length} items');
    } catch (e, stackTrace) {
      logger.e('Failed to save cart', 
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Загружает корзину из локального хранилища
  Future<List<CartItem>> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cartKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        logger.i('No saved cart found');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final items = jsonList
          .map((json) => _cartItemFromJson(json as Map<String, dynamic>))
          .toList();
      
      logger.i('Cart loaded: ${items.length} items');
      return items;
    } catch (e, stackTrace) {
      logger.e('Failed to load cart', 
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Очищает сохраненную корзину
  Future<void> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      logger.i('Cart cleared');
    } catch (e, stackTrace) {
      logger.e('Failed to clear cart', 
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Преобразует CartItem в JSON
  Map<String, dynamic> _cartItemToJson(CartItem item) {
    return {
      'productId': item.productId,
      'quantity': item.quantity,
      'note': item.note,
      'product': _productToJson(item.product),
    };
  }

  /// Преобразует JSON в CartItem
  CartItem _cartItemFromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] as String,
      quantity: json['quantity'] as int,
      note: json['note'] as String?,
      product: _productFromJson(json['product'] as Map<String, dynamic>),
    );
  }

  /// Преобразует Product в JSON
  Map<String, dynamic> _productToJson(Product product) {
    return {
      'id': product.id,
      'businessId': product.businessId,
      'title': product.title,
      'description': product.description,
      'price': product.price,
      'currency': product.currency,
      'sku': product.sku,
      'imageUrl': product.imageUrl,
      'isActive': product.isActive,
      'categoryIds': product.categoryIds,
      'createdAt': product.createdAt.toIso8601String(),
      'updatedAt': product.updatedAt.toIso8601String(),
      'discount_percentage': product.discountPercentage,
      'discount_price': product.discountPrice,
      'discount_valid_from': product.discountValidFrom?.toIso8601String(),
      'discount_valid_until': product.discountValidUntil?.toIso8601String(),
    };
  }

  /// Преобразует JSON в Product
  Product _productFromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'RUB',
      sku: json['sku'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      categoryIds: (json['categoryIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      discountPercentage: json['discount_percentage'] != null 
          ? (json['discount_percentage'] as num).toDouble() 
          : null,
      discountPrice: json['discount_price'] != null 
          ? (json['discount_price'] as num).toDouble() 
          : null,
      discountValidFrom: json['discount_valid_from'] != null 
          ? DateTime.parse(json['discount_valid_from'] as String) 
          : null,
      discountValidUntil: json['discount_valid_until'] != null 
          ? DateTime.parse(json['discount_valid_until'] as String) 
          : null,
    );
  }
}

