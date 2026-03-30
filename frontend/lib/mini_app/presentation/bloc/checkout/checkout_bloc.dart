import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/mini_app/domain/entities/order.dart' as entities;
import 'package:tg_store/mini_app/domain/repositories/order_repository.dart';
import 'package:dio/dio.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final OrderRepository orderRepository;
  final ApiClient _apiClient = ApiClient();

  CheckoutBloc({required this.orderRepository}) : super(const CheckoutInitial()) {
    on<SubmitOrder>(_onSubmitOrder);
    on<ResetCheckout>(_onResetCheckout);
    on<UpdateCustomerName>(_onUpdateCustomerName);
    on<UpdateCustomerPhone>(_onUpdateCustomerPhone);
    on<UpdateCustomerAddress>(_onUpdateCustomerAddress);
    on<UpdateDeliveryMethod>(_onUpdateDeliveryMethod);
    on<UpdatePaymentMethod>(_onUpdatePaymentMethod);
    on<CalculateDeliveryCost>(_onCalculateDeliveryCost);
    on<ValidatePromocode>(_onValidatePromocode);
    on<ClearPromocode>(_onClearPromocode);
    on<UpdateLoyaltyPointsToSpend>(_onUpdateLoyaltyPointsToSpend);
  }

  Future<void> _onSubmitOrder(
    SubmitOrder event,
    Emitter<CheckoutState> emit,
  ) async {
    logger.i('SubmitOrder event received');
    emit(CheckoutLoading());
    
    try {
      logger.d('Creating order with data:');
      logger.d('  Name: ${event.customerName}');
      logger.d('  Phone: ${event.customerPhone}');
      logger.d('  Address: ${event.customerAddress}');
      logger.d('  Delivery: ${event.deliveryMethod}');
      logger.d('  Payment: ${event.paymentMethod}');
      logger.d('  Items: ${event.items.length}');
      logger.d('  User Telegram ID: ${event.userTelegramId}');
      
      // Вызываем реальный API
      final result = await orderRepository.createOrder(
        businessSlug: event.businessSlug,
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        customerAddress: event.customerAddress,
        items: event.items,
        paymentMethod: event.paymentMethod,
        deliveryMethod: event.deliveryMethod,
        userTelegramId: event.userTelegramId,
        promocodeCode: event.promocodeCode,
        loyaltyPointsToSpend: event.loyaltyPointsToSpend,
      );
      
      result.fold(
        (failure) {
          logger.e('❌ Failed to create order: ${failure.message}');
          emit(CheckoutError(failure.message));
        },
        (order) {
          logger.i('✅ Order created successfully: ${order.id}');
          logger.d('Order payment method: ${order.paymentMethod}');
          logger.d('Order metadata: ${order.metadata}');
          logger.d('Order metadata is null: ${order.metadata == null}');
          
          // Извлекаем payment_url из metadata, если он есть
          String? paymentUrl;
          if (order.metadata != null) {
            logger.d('Order metadata keys: ${order.metadata!.keys.toList()}');
            logger.d('Order metadata contains payment_url: ${order.metadata!.containsKey('payment_url')}');
            
            if (order.metadata!.containsKey('payment_url')) {
              paymentUrl = order.metadata!['payment_url'] as String?;
              logger.i('💰 Payment URL extracted from metadata: $paymentUrl');
              logger.d('Payment URL type: ${paymentUrl.runtimeType}');
              logger.d('Payment URL is null: ${paymentUrl == null}');
              logger.d('Payment URL is empty: ${paymentUrl?.isEmpty ?? true}');
            } else {
              logger.w('⚠️ Order metadata does not contain payment_url key');
              logger.d('Available metadata keys: ${order.metadata!.keys.toList()}');
            }
          } else {
            logger.w('⚠️ Order metadata is null');
          }
          
          logger.d('Emitting CheckoutSuccess with paymentUrl: $paymentUrl');
          emit(CheckoutSuccess(order, paymentUrl: paymentUrl));
          logger.d('CheckoutSuccess state emitted');
        },
      );
    } catch (e) {
      logger.e('Error creating order', error: e);
      emit(CheckoutError('Ошибка при создании заказа: $e'));
    }
  }

  void _onResetCheckout(ResetCheckout event, Emitter<CheckoutState> emit) {
    logger.i('ResetCheckout event received');
    emit(const CheckoutInitial());
  }

  Future<void> _onValidatePromocode(
    ValidatePromocode event,
    Emitter<CheckoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CheckoutInitial) return;

    // Устанавливаем флаг валидации
    emit(CheckoutInitial(
      customerName: currentState.customerName,
      customerPhone: currentState.customerPhone,
      customerAddress: currentState.customerAddress,
      deliveryMethod: currentState.deliveryMethod,
      paymentMethod: currentState.paymentMethod,
      deliveryCost: currentState.deliveryCost,
      isCalculatingDelivery: currentState.isCalculatingDelivery,
      promocode: currentState.promocode,
      promocodeDiscount: currentState.promocodeDiscount,
      isValidatingPromocode: true,
      promocodeError: null,
      loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
      loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
    ));

    try {
      // Сначала получаем business_id через business_slug
      String businessId;
      try {
        final businessResponse = await _apiClient.dio.get(
          ApiConstants.businessBySlug(event.businessSlug),
        );

        if (businessResponse.statusCode != 200) {
          final errorMsg = _extractErrorMessage(businessResponse.data) ?? 
              'Не удалось загрузить данные бизнеса';
          emit(CheckoutInitial(
            customerName: currentState.customerName,
            customerPhone: currentState.customerPhone,
            customerAddress: currentState.customerAddress,
            deliveryMethod: currentState.deliveryMethod,
            paymentMethod: currentState.paymentMethod,
            deliveryCost: currentState.deliveryCost,
            isCalculatingDelivery: currentState.isCalculatingDelivery,
            promocode: null,
            promocodeDiscount: null,
            isValidatingPromocode: false,
            promocodeError: errorMsg,
            loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
            loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
          ));
          return;
        }

        final businessData = businessResponse.data;
        if (businessData is! Map || businessData['id'] == null) {
          emit(CheckoutInitial(
            customerName: currentState.customerName,
            customerPhone: currentState.customerPhone,
            customerAddress: currentState.customerAddress,
            deliveryMethod: currentState.deliveryMethod,
            paymentMethod: currentState.paymentMethod,
            deliveryCost: currentState.deliveryCost,
            isCalculatingDelivery: currentState.isCalculatingDelivery,
            promocode: null,
            promocodeDiscount: null,
            isValidatingPromocode: false,
            promocodeError: 'Неверный формат ответа от сервера',
            loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
            loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
          ));
          return;
        }

        businessId = businessData['id'] as String;
      } on DioException catch (e) {
        final errorMsg = _extractErrorMessageFromDioException(e) ?? 
            'Ошибка подключения к серверу';
        emit(CheckoutInitial(
          customerName: currentState.customerName,
          customerPhone: currentState.customerPhone,
          customerAddress: currentState.customerAddress,
          deliveryMethod: currentState.deliveryMethod,
          paymentMethod: currentState.paymentMethod,
          deliveryCost: currentState.deliveryCost,
          isCalculatingDelivery: currentState.isCalculatingDelivery,
          promocode: null,
          promocodeDiscount: null,
          isValidatingPromocode: false,
          promocodeError: errorMsg,
          loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
          loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
        ));
        return;
      }

      // Валидируем промокод
      try {
        logger.d('🔍 Validating promocode: ${event.promocode}, user_telegram_id: ${event.userTelegramId}, order_amount: ${event.orderAmount}');
        final response = await _apiClient.dio.post(
          ApiConstants.validatePromocode(businessId),
          data: {
            'code': event.promocode,
            'order_amount': event.orderAmount,
            'user_telegram_id': event.userTelegramId,
          },
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is! Map) {
            emit(CheckoutInitial(
              customerName: currentState.customerName,
              customerPhone: currentState.customerPhone,
              customerAddress: currentState.customerAddress,
              deliveryMethod: currentState.deliveryMethod,
              paymentMethod: currentState.paymentMethod,
              deliveryCost: currentState.deliveryCost,
              isCalculatingDelivery: currentState.isCalculatingDelivery,
              promocode: null,
              promocodeDiscount: null,
              isValidatingPromocode: false,
              promocodeError: 'Неверный формат ответа от сервера',
              loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
              loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
            ));
            return;
          }

          final isValid = data['valid'] as bool? ?? false;
          final discountAmount = data['discount_amount'];
          final error = data['error'] as String?;

          logger.d('📋 Promocode validation response: valid=$isValid, discount=$discountAmount, error=$error');

          // Проверяем, что промокод валиден и есть размер скидки
          if (isValid == true && discountAmount != null) {
            final discount = discountAmount is num 
                ? discountAmount.toDouble() 
                : (double.tryParse(discountAmount.toString()) ?? 0.0);
            
            logger.i('✅ Promocode validated: ${event.promocode}, discount: $discount');
            emit(CheckoutInitial(
              customerName: currentState.customerName,
              customerPhone: currentState.customerPhone,
              customerAddress: currentState.customerAddress,
              deliveryMethod: currentState.deliveryMethod,
              paymentMethod: currentState.paymentMethod,
              deliveryCost: currentState.deliveryCost,
              isCalculatingDelivery: currentState.isCalculatingDelivery,
              promocode: event.promocode,
              promocodeDiscount: discount,
              isValidatingPromocode: false,
              promocodeError: null,
              loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
              loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
            ));
          } else {
            // Промокод недействителен или есть ошибка
            final errorMessage = error ?? 'Промокод недействителен';
            logger.w('⚠️ Promocode invalid or error: $errorMessage (valid=$isValid, discount=$discountAmount)');
            
            // Всегда показываем ошибку, даже если valid=false без явной ошибки
            emit(CheckoutInitial(
              customerName: currentState.customerName,
              customerPhone: currentState.customerPhone,
              customerAddress: currentState.customerAddress,
              deliveryMethod: currentState.deliveryMethod,
              paymentMethod: currentState.paymentMethod,
              deliveryCost: currentState.deliveryCost,
              isCalculatingDelivery: currentState.isCalculatingDelivery,
              promocode: null,
              promocodeDiscount: null,
              isValidatingPromocode: false,
              promocodeError: errorMessage,
              loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
              loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
            ));
          }
        } else {
          final errorMsg = _extractErrorMessage(response.data) ?? 
              'Ошибка при проверке промокода';
          emit(CheckoutInitial(
            customerName: currentState.customerName,
            customerPhone: currentState.customerPhone,
            customerAddress: currentState.customerAddress,
            deliveryMethod: currentState.deliveryMethod,
            paymentMethod: currentState.paymentMethod,
            deliveryCost: currentState.deliveryCost,
            isCalculatingDelivery: currentState.isCalculatingDelivery,
            promocode: null,
            promocodeDiscount: null,
            isValidatingPromocode: false,
            promocodeError: errorMsg,
            loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
            loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
          ));
        }
      } on DioException catch (e) {
        logger.e('DioException validating promocode', error: e);
        final errorMessage = _extractErrorMessageFromDioException(e) ?? 
            'Ошибка при проверке промокода';
        
        emit(CheckoutInitial(
          customerName: currentState.customerName,
          customerPhone: currentState.customerPhone,
          customerAddress: currentState.customerAddress,
          deliveryMethod: currentState.deliveryMethod,
          paymentMethod: currentState.paymentMethod,
          deliveryCost: currentState.deliveryCost,
          isCalculatingDelivery: currentState.isCalculatingDelivery,
          promocode: null,
          promocodeDiscount: null,
          isValidatingPromocode: false,
          promocodeError: errorMessage,
          loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
          loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
        ));
      }
    } catch (e, stackTrace) {
      logger.e('Unexpected error validating promocode', error: e, stackTrace: stackTrace);
      String errorMessage = 'Ошибка при проверке промокода';
      if (e is Exception) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        if (msg.isNotEmpty && msg != 'Exception') {
          errorMessage = msg;
        }
      }
      
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: currentState.deliveryCost,
        isCalculatingDelivery: currentState.isCalculatingDelivery,
        promocode: null,
        promocodeDiscount: null,
        isValidatingPromocode: false,
        promocodeError: errorMessage,
        loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
        loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
      ));
    }
  }

  /// Извлекает сообщение об ошибке из ответа сервера
  String? _extractErrorMessage(dynamic responseData) {
    if (responseData == null) return null;
    
    if (responseData is Map) {
      return responseData['detail'] as String? ??
          responseData['error'] as String? ??
          responseData['message'] as String? ??
          (responseData['errors'] is List && (responseData['errors'] as List).isNotEmpty
              ? (responseData['errors'] as List).first.toString()
              : null);
    }
    
    if (responseData is String) {
      return responseData;
    }
    
    return null;
  }

  /// Извлекает сообщение об ошибке из DioException
  String? _extractErrorMessageFromDioException(DioException e) {
    // Сначала пытаемся извлечь из response.data
    if (e.response?.data != null) {
      final errorMsg = _extractErrorMessage(e.response!.data);
      if (errorMsg != null && errorMsg.isNotEmpty) {
        return errorMsg;
      }
    }
    
    // Обрабатываем специфичные типы ошибок
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Превышено время ожидания. Проверьте подключение к интернету';
      
      case DioExceptionType.badResponse:
        if (e.response?.statusCode != null) {
          switch (e.response!.statusCode) {
            case 404:
              return 'Сервис не найден';
            case 500:
              return 'Ошибка на сервере. Попробуйте позже';
            case 503:
              return 'Сервис временно недоступен';
            default:
              return 'Ошибка сервера (${e.response!.statusCode})';
          }
        }
        return 'Ошибка при обработке запроса';
      
      case DioExceptionType.cancel:
        return 'Запрос отменен';
      
      case DioExceptionType.connectionError:
        return 'Ошибка подключения. Проверьте интернет-соединение';
      
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true) {
          return 'Нет подключения к интернету';
        }
        return e.message ?? 'Неизвестная ошибка';
      
      default:
        return e.message ?? 'Ошибка при проверке промокода';
    }
  }

  void _onClearPromocode(ClearPromocode event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: currentState.deliveryCost,
        isCalculatingDelivery: currentState.isCalculatingDelivery,
        promocode: null,
        promocodeDiscount: null,
        isValidatingPromocode: false,
        promocodeError: null,
        loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
        loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
      ));
    }
  }

  void _onUpdateCustomerName(UpdateCustomerName event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      emit(CheckoutInitial(
        customerName: event.name,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: currentState.deliveryCost,
        isCalculatingDelivery: currentState.isCalculatingDelivery,
        promocode: currentState.promocode,
        promocodeDiscount: currentState.promocodeDiscount,
        isValidatingPromocode: currentState.isValidatingPromocode,
        promocodeError: currentState.promocodeError,
        loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
        loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
      ));
    }
  }

  void _onUpdateCustomerPhone(UpdateCustomerPhone event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: event.phone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: currentState.deliveryCost,
        isCalculatingDelivery: currentState.isCalculatingDelivery,
        promocode: currentState.promocode,
        promocodeDiscount: currentState.promocodeDiscount,
        isValidatingPromocode: currentState.isValidatingPromocode,
        promocodeError: currentState.promocodeError,
        loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
        loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
      ));
    }
  }

  void _onUpdateCustomerAddress(UpdateCustomerAddress event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      // Обновляем адрес, но НЕ рассчитываем доставку автоматически
      // Расчет будет происходить только при выборе адреса из подсказок
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: event.address,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: null, // Сбрасываем стоимость доставки при изменении адреса
        isCalculatingDelivery: false,
        promocode: currentState.promocode,
        promocodeDiscount: currentState.promocodeDiscount,
        isValidatingPromocode: currentState.isValidatingPromocode,
        promocodeError: currentState.promocodeError,
        loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
        loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
      ));
    }
  }

  void _onUpdateDeliveryMethod(UpdateDeliveryMethod event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      final newState = CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: event.method,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: event.method == 'pickup' ? null : currentState.deliveryCost,
        isCalculatingDelivery: false,
        promocode: currentState.promocode,
        promocodeDiscount: currentState.promocodeDiscount,
        isValidatingPromocode: currentState.isValidatingPromocode,
        promocodeError: currentState.promocodeError,
      );
      emit(newState);
      
      // Если выбрана доставка и адрес указан, рассчитываем стоимость
      if (event.method == 'delivery' && currentState.customerAddress.isNotEmpty) {
        add(CalculateDeliveryCost(
          customerAddress: currentState.customerAddress,
          items: [],
        ));
      }
    }
  }

  void _onUpdatePaymentMethod(UpdatePaymentMethod event, Emitter<CheckoutState> emit) {
    final currentState = state;
    if (currentState is CheckoutInitial) {
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: event.method,
        deliveryCost: currentState.deliveryCost,
        isCalculatingDelivery: currentState.isCalculatingDelivery,
        promocode: currentState.promocode,
        promocodeDiscount: currentState.promocodeDiscount,
        isValidatingPromocode: currentState.isValidatingPromocode,
        promocodeError: currentState.promocodeError,
        loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
        loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
      ));
    }
  }

  Future<void> _onCalculateDeliveryCost(
    CalculateDeliveryCost event,
    Emitter<CheckoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CheckoutInitial) return;
    
    // Если адрес пустой или выбрана самовывоз, не рассчитываем
    if (event.customerAddress.isEmpty || currentState.deliveryMethod != 'delivery') {
      return;
    }
    
    logger.i('Calculating delivery cost for address: ${event.customerAddress}');
    
    // Устанавливаем флаг расчета
    emit(CheckoutInitial(
      customerName: currentState.customerName,
      customerPhone: currentState.customerPhone,
      customerAddress: currentState.customerAddress,
      deliveryMethod: currentState.deliveryMethod,
      paymentMethod: currentState.paymentMethod,
      deliveryCost: currentState.deliveryCost,
      isCalculatingDelivery: true,
      promocode: currentState.promocode,
      promocodeDiscount: currentState.promocodeDiscount,
      isValidatingPromocode: currentState.isValidatingPromocode,
      promocodeError: currentState.promocodeError,
      loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
      loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
    ));
    
    try {
      // Адрес отправления (из настроек бэкенда)
      final fromAddress = {
        "fullname": "Москва, 1-й проезд Марьиной Рощи, дом 7/9",
        "coordinates": [37.6000, 55.8000],
        "city": "Москва",
        "country": "Россия",
        "street": "1-й проезд Марьиной Рощи",
      };
      
      // Адрес назначения (адрес клиента)
      // Используем примерные координаты, так как геокодер требует API ключ
      final toAddress = {
        "fullname": event.customerAddress,
        "coordinates": [37.6173, 55.7558], // Примерные координаты (центр Москвы)
        "city": "Москва",
        "country": "Россия",
        "street": event.customerAddress,
      };
      
      // Подготавливаем товары для расчета
      // Если товары не переданы, используем примерные значения (1 товар, 0.5 кг)
      final items = event.items.isNotEmpty
          ? event.items.map((item) {
              return {
                "quantity": item['quantity'] ?? 1,
                "weight": (item['weight'] ?? 0.1).toDouble(), // Минимальный вес
                "size": item['size'] ?? {
                  "length": 0.05,
                  "width": 0.05,
                  "height": 0.05,
                },
              };
            }).toList()
          : [
              {
                "quantity": 1,
                "weight": 0.1, // Минимальный вес для снижения стоимости
                "size": {
                  "length": 0.05,
                  "width": 0.05,
                  "height": 0.05,
                },
              }
            ];
      
      logger.d('Calculating delivery with ${items.length} items');
      
      // Вызываем API расчета доставки
      final response = await _apiClient.dio.post(
        ApiConstants.calculateDeliveryCost(),
        data: {
          "from_address": fromAddress,
          "to_address": toAddress,
          "items": items,
          "taxi_classes": ["courier"],
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final offers = data['offers'] as List?;
        
        if (offers != null && offers.isNotEmpty) {
          final firstOffer = offers[0] as Map<String, dynamic>;
          final price = firstOffer['price'] as Map<String, dynamic>;
          final totalPrice = price['total_price_with_vat'] ?? price['total_price'];
          final deliveryCost = double.tryParse(totalPrice.toString()) ?? 0.0;
          
          logger.i('✅ Delivery cost calculated: $deliveryCost RUB');
          
          emit(CheckoutInitial(
            customerName: currentState.customerName,
            customerPhone: currentState.customerPhone,
            customerAddress: currentState.customerAddress,
            deliveryMethod: currentState.deliveryMethod,
            paymentMethod: currentState.paymentMethod,
            deliveryCost: deliveryCost,
            isCalculatingDelivery: false,
            promocode: currentState.promocode,
            promocodeDiscount: currentState.promocodeDiscount,
            isValidatingPromocode: currentState.isValidatingPromocode,
            promocodeError: currentState.promocodeError,
            loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
            loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
          ));
        } else {
          logger.w('⚠️ No delivery offers found');
          emit(CheckoutInitial(
            customerName: currentState.customerName,
            customerPhone: currentState.customerPhone,
            customerAddress: currentState.customerAddress,
            deliveryMethod: currentState.deliveryMethod,
            paymentMethod: currentState.paymentMethod,
            deliveryCost: null,
            isCalculatingDelivery: false,
            promocode: currentState.promocode,
            promocodeDiscount: currentState.promocodeDiscount,
            isValidatingPromocode: currentState.isValidatingPromocode,
            promocodeError: currentState.promocodeError,
            loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
            loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
          ));
        }
      } else {
        throw Exception('Failed to calculate delivery cost: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logger.e('Error calculating delivery cost', error: e);
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: null,
        isCalculatingDelivery: false,
        promocode: currentState.promocode,
        promocodeDiscount: currentState.promocodeDiscount,
        isValidatingPromocode: currentState.isValidatingPromocode,
        promocodeError: currentState.promocodeError,
        loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
        loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
      ));
    } catch (e) {
      logger.e('Unexpected error calculating delivery cost', error: e);
      emit(CheckoutInitial(
        customerName: currentState.customerName,
        customerPhone: currentState.customerPhone,
        customerAddress: currentState.customerAddress,
        deliveryMethod: currentState.deliveryMethod,
        paymentMethod: currentState.paymentMethod,
        deliveryCost: null,
        isCalculatingDelivery: false,
        promocode: currentState.promocode,
        promocodeDiscount: currentState.promocodeDiscount,
        isValidatingPromocode: currentState.isValidatingPromocode,
        promocodeError: currentState.promocodeError,
        loyaltyPointsToSpend: currentState.loyaltyPointsToSpend,
        loyaltyPointsDiscount: currentState.loyaltyPointsDiscount,
      ));
    }
  }

  void _onUpdateLoyaltyPointsToSpend(
    UpdateLoyaltyPointsToSpend event,
    Emitter<CheckoutState> emit,
  ) {
    final currentState = state;
    if (currentState is! CheckoutInitial) return;

    // Рассчитываем скидку: 1 балл = 1 рубль
    // Ограничение до 90% будет применяться на бэкенде
    final discount = event.points ?? 0.0;

    emit(CheckoutInitial(
      customerName: currentState.customerName,
      customerPhone: currentState.customerPhone,
      customerAddress: currentState.customerAddress,
      deliveryMethod: currentState.deliveryMethod,
      paymentMethod: currentState.paymentMethod,
      deliveryCost: currentState.deliveryCost,
      isCalculatingDelivery: currentState.isCalculatingDelivery,
      promocode: currentState.promocode,
      promocodeDiscount: currentState.promocodeDiscount,
      isValidatingPromocode: currentState.isValidatingPromocode,
      promocodeError: currentState.promocodeError,
      loyaltyPointsToSpend: event.points,
      loyaltyPointsDiscount: discount,
    ));
  }
}

