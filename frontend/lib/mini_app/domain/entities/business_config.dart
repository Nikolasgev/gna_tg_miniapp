import 'package:equatable/equatable.dart';

class BusinessConfig extends Equatable {
  final String businessId;
  final String name;
  final String? logo;
  final String? primaryColor;
  final String? backgroundColor;
  final String? textColor;
  final String currency;
  final Map<String, dynamic>? workingHours;
  final bool supportsDelivery;
  final bool supportsPickup;
  final List<String> paymentMethods;

  const BusinessConfig({
    required this.businessId,
    required this.name,
    this.logo,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.currency = 'RUB',
    this.workingHours,
    this.supportsDelivery = false,
    this.supportsPickup = true,
    this.paymentMethods = const [],
  });

  @override
  List<Object?> get props => [
        businessId,
        name,
        logo,
        primaryColor,
        backgroundColor,
        textColor,
        currency,
        workingHours,
        supportsDelivery,
        supportsPickup,
        paymentMethods,
      ];
}

