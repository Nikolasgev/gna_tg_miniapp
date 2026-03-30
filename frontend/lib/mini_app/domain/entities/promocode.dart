import 'package:equatable/equatable.dart';

class Promocode extends Equatable {
  final String id;
  final String businessId;
  final String code;
  final String? description;
  final String discountType;  // "percentage" или "fixed"
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscountAmount;
  final int? maxUses;
  final int usesCount;
  final int? maxUsesPerUser;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Promocode({
    required this.id,
    required this.businessId,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.maxUses,
    required this.usesCount,
    this.maxUsesPerUser,
    this.validFrom,
    this.validUntil,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Рассчитать размер скидки для указанной суммы заказа
  double calculateDiscount(double orderAmount) {
    double discount;
    
    if (discountType == 'percentage') {
      discount = orderAmount * (discountValue / 100);
      if (maxDiscountAmount != null) {
        discount = discount > maxDiscountAmount! ? maxDiscountAmount! : discount;
      }
    } else {
      discount = discountValue;
    }
    
    // Скидка не может быть больше суммы заказа
    if (discount > orderAmount) {
      discount = orderAmount;
    }
    
    return discount;
  }

  /// Проверить, валиден ли промокод для указанной суммы заказа
  bool isValidForAmount(double orderAmount) {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    
    if (minOrderAmount != null && orderAmount < minOrderAmount!) return false;
    if (maxUses != null && usesCount >= maxUses!) return false;
    
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        businessId,
        code,
        description,
        discountType,
        discountValue,
        minOrderAmount,
        maxDiscountAmount,
        maxUses,
        usesCount,
        maxUsesPerUser,
        validFrom,
        validUntil,
        isActive,
        createdAt,
        updatedAt,
      ];
}

