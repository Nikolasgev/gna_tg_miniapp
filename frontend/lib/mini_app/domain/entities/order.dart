import 'package:equatable/equatable.dart';

enum OrderStatus {
  new_,
  accepted,
  preparing,
  ready,
  cancelled,
  completed,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

enum PaymentMethod {
  cash,
  online,
}

class OrderItem extends Equatable {
  final String id;
  final String productId;
  final String titleSnapshot;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.titleSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        titleSnapshot,
        quantity,
        unitPrice,
        totalPrice,
      ];
}

class Order extends Equatable {
  final String id;
  final String businessId;
  final int? userTelegramId;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final double totalAmount;
  final double? subtotalAmount;  // Сумма до применения скидок
  final double? discountAmount;  // Общая сумма скидки
  final double? deliveryCost;  // Стоимость доставки
  final String? deliveryMethod;  // Способ доставки (pickup/delivery)
  final String? promocodeId;  // ID применённого промокода
  final double? loyaltyPointsEarned;  // Баллы, заработанные за заказ
  final double? loyaltyPointsSpent;  // Баллы, потраченные на заказ
  final String currency;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final Map<String, dynamic>? metadata;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.businessId,
    this.userTelegramId,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    required this.totalAmount,
    this.subtotalAmount,
    this.discountAmount,
    this.deliveryCost,
    this.deliveryMethod,
    this.promocodeId,
    this.loyaltyPointsEarned,
    this.loyaltyPointsSpent,
    this.currency = 'RUB',
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.metadata,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        userTelegramId,
        customerName,
        customerPhone,
        customerAddress,
        totalAmount,
        subtotalAmount,
        discountAmount,
        deliveryCost,
        deliveryMethod,
        promocodeId,
        loyaltyPointsEarned,
        loyaltyPointsSpent,
        currency,
        status,
        paymentStatus,
        paymentMethod,
        metadata,
        items,
        createdAt,
        updatedAt,
      ];
}

