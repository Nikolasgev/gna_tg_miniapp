part of 'checkout_bloc.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String deliveryMethod; // pickup or delivery
  final String paymentMethod; // cash or online
  final double? deliveryCost; // Стоимость доставки
  final bool isCalculatingDelivery; // Идет ли расчет доставки
  final String? promocode; // Промокод
  final double? promocodeDiscount; // Размер скидки по промокоду
  final bool isValidatingPromocode; // Идет ли валидация промокода
  final String? promocodeError; // Ошибка валидации промокода
  final double? loyaltyPointsToSpend; // Баллы для списания
  final double? loyaltyPointsDiscount; // Размер скидки от баллов

  const CheckoutInitial({
    this.customerName = '',
    this.customerPhone = '',
    this.customerAddress = '',
    this.deliveryMethod = 'pickup',
    this.paymentMethod = 'cash',
    this.deliveryCost,
    this.isCalculatingDelivery = false,
    this.promocode,
    this.promocodeDiscount,
    this.isValidatingPromocode = false,
    this.promocodeError,
    this.loyaltyPointsToSpend,
    this.loyaltyPointsDiscount,
  });

  @override
  List<Object?> get props => [
        customerName,
        customerPhone,
        customerAddress,
        deliveryMethod,
        paymentMethod,
        deliveryCost,
        isCalculatingDelivery,
        promocode,
        promocodeDiscount,
        isValidatingPromocode,
        promocodeError,
        loyaltyPointsToSpend,
        loyaltyPointsDiscount,
      ];
}

class CheckoutLoading extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final entities.Order order;
  final String? paymentUrl; // URL для оплаты (если paymentMethod == 'online')

  const CheckoutSuccess(this.order, {this.paymentUrl});

  @override
  List<Object?> get props => [order, paymentUrl];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError(this.message);

  @override
  List<Object?> get props => [message];
}

