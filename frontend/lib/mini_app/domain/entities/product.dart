import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String businessId;
  final String title;
  final String? description;
  final double price;
  final String currency;
  final String? sku;
  final String? imageUrl;
  final Map<String, dynamic>? variations;  // Вариации товара (размер, цвет и т.д.)
  final bool isActive;
  final List<String> categoryIds;
  
  // Поля для скидок
  final double? discountPercentage;  // Процент скидки (0-100)
  final double? discountPrice;  // Цена со скидкой
  final DateTime? discountValidFrom;  // Дата начала действия скидки
  final DateTime? discountValidUntil;  // Дата окончания действия скидки
  
  // Управление складом
  final int? stockQuantity;  // Количество товара на складе (null = неограниченно)
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.businessId,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'RUB',
    this.sku,
    this.imageUrl,
    this.variations,
    this.isActive = true,
    this.categoryIds = const [],
    this.discountPercentage,
    this.discountPrice,
    this.discountValidFrom,
    this.discountValidUntil,
    this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Получить актуальную цену с учётом скидки
  double get currentPrice {
    final now = DateTime.now();
    
    // Проверяем, активна ли скидка
    bool isDiscountActive = false;
    if (discountPercentage != null || discountPrice != null) {
      if (discountValidFrom != null && now.isBefore(discountValidFrom!)) {
        isDiscountActive = false;
      } else if (discountValidUntil != null && now.isAfter(discountValidUntil!)) {
        isDiscountActive = false;
      } else {
        isDiscountActive = true;
      }
    }
    
    if (!isDiscountActive) {
      return price;
    }
    
    // Если указана фиксированная цена со скидкой
    if (discountPrice != null) {
      return discountPrice!;
    }
    
    // Если указан процент скидки
    if (discountPercentage != null) {
      final discountAmount = price * (discountPercentage! / 100);
      return (price - discountAmount);
    }
    
    return price;
  }
  
  /// Проверить, есть ли активная скидка
  bool get hasActiveDiscount {
    final now = DateTime.now();
    if (discountPercentage == null && discountPrice == null) {
      return false;
    }
    
    if (discountValidFrom != null && now.isBefore(discountValidFrom!)) {
      return false;
    }
    if (discountValidUntil != null && now.isAfter(discountValidUntil!)) {
      return false;
    }
    
    return true;
  }
  
  /// Получить размер скидки в рублях
  double get discountAmount {
    if (!hasActiveDiscount) {
      return 0.0;
    }
    return price - currentPrice;
  }
  
  /// Проверить, есть ли товар в наличии
  bool get isInStock {
    // Если stockQuantity == null, товар считается неограниченным
    if (stockQuantity == null) {
      return true;
    }
    return stockQuantity! > 0;
  }
  
  /// Получить количество товара на складе (или null, если неограниченно)
  int? get availableQuantity => stockQuantity;

  @override
  List<Object?> get props => [
        id,
        businessId,
        title,
        description,
        price,
        currency,
        sku,
        imageUrl,
        variations,
        isActive,
        categoryIds,
        discountPercentage,
        discountPrice,
        discountValidFrom,
        discountValidUntil,
        stockQuantity,
        createdAt,
        updatedAt,
      ];
}

