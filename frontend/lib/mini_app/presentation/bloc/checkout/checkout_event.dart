part of 'checkout_bloc.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

class SubmitOrder extends CheckoutEvent {
  final String businessSlug;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final List<Map<String, dynamic>> items;
  final String deliveryMethod; // pickup or delivery
  final String paymentMethod; // cash or online
  final double totalAmount;
  final int? userTelegramId;
  final String? promocodeCode; // Промокод для применения
  final double? loyaltyPointsToSpend; // Баллы для списания

  const SubmitOrder({
    required this.businessSlug,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.totalAmount,
    this.userTelegramId,
    this.promocodeCode,
    this.loyaltyPointsToSpend,
  });

  @override
  List<Object?> get props => [
        businessSlug,
        customerName,
        customerPhone,
        customerAddress,
        items,
        deliveryMethod,
        paymentMethod,
        totalAmount,
        userTelegramId,
        promocodeCode,
        loyaltyPointsToSpend,
      ];
}

class ResetCheckout extends CheckoutEvent {
  const ResetCheckout();
}

class UpdateCustomerName extends CheckoutEvent {
  final String name;

  const UpdateCustomerName(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdateCustomerPhone extends CheckoutEvent {
  final String phone;

  const UpdateCustomerPhone(this.phone);

  @override
  List<Object?> get props => [phone];
}

class UpdateCustomerAddress extends CheckoutEvent {
  final String address;

  const UpdateCustomerAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class UpdateDeliveryMethod extends CheckoutEvent {
  final String method; // pickup or delivery

  const UpdateDeliveryMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class UpdatePaymentMethod extends CheckoutEvent {
  final String method; // cash or online

  const UpdatePaymentMethod(this.method);

  @override
  List<Object?> get props => [method];
}

class CalculateDeliveryCost extends CheckoutEvent {
  final String customerAddress;
  final List<Map<String, dynamic>> items; // Товары для расчета веса

  const CalculateDeliveryCost({
    required this.customerAddress,
    required this.items,
  });

  @override
  List<Object?> get props => [customerAddress, items];
}

class ValidatePromocode extends CheckoutEvent {
  final String businessSlug;
  final String promocode;
  final double orderAmount; // Сумма заказа для валидации
  final int? userTelegramId;

  const ValidatePromocode({
    required this.businessSlug,
    required this.promocode,
    required this.orderAmount,
    this.userTelegramId,
  });

  @override
  List<Object?> get props => [businessSlug, promocode, orderAmount, userTelegramId];
}

class ClearPromocode extends CheckoutEvent {
  const ClearPromocode();
}

class UpdateLoyaltyPointsToSpend extends CheckoutEvent {
  final double? points;

  const UpdateLoyaltyPointsToSpend(this.points);

  @override
  List<Object?> get props => [points];
}

