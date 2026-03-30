import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/domain/repositories/order_repository.dart' as domain;
import 'package:tg_store/mini_app/domain/entities/order.dart' as entities;

class OrderRepositoryImpl implements domain.OrderRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<Either<Failure, entities.Order>> createOrder({
    required String businessSlug,
    required String customerName,
    required String customerPhone,
    String? customerAddress,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String deliveryMethod,
    int? userTelegramId,
    String? promocodeCode,
    double? loyaltyPointsToSpend,
  }) async {
    try {
      final data = {
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'items': items.map((item) => {
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'note': item['note'],
          'selected_variations': item['selected_variations'],
        }).toList(),
        'payment_method': paymentMethod,
        'delivery_method': deliveryMethod,
      };
      
      if (userTelegramId != null) {
        data['user_telegram_id'] = userTelegramId;
      }
      
      if (promocodeCode != null && promocodeCode.isNotEmpty) {
        data['promocode'] = promocodeCode;
      }
      
      if (loyaltyPointsToSpend != null && loyaltyPointsToSpend > 0) {
        data['loyalty_points_to_spend'] = loyaltyPointsToSpend;
      }
      
      final response = await _apiClient.dio.post(
        ApiConstants.createOrder(businessSlug),
        data: data,
      );

      if (response.statusCode == 200) {
        final orderData = response.data;
        logger.d('=== Order creation response received ===');
        logger.d('Full response data: $orderData');
        logger.d('Response data type: ${orderData.runtimeType}');
        
        final orderId = orderData['order_id'] as String;
        logger.d('Order ID: $orderId');
        
        // Проверяем наличие payment информации
        logger.d('Checking for payment data in response...');
        final paymentData = orderData['payment'] as Map<String, dynamic>?;
        logger.d('Payment data: $paymentData');
        logger.d('Payment data is null: ${paymentData == null}');
        logger.d('Payment method from request: $paymentMethod');
        
        String? checkoutUrl;
        if (paymentData != null) {
          logger.d('Payment data keys: ${paymentData.keys.toList()}');
          checkoutUrl = paymentData['checkout_url'] as String?;
          logger.i('💰 Payment data received: $paymentData');
          logger.i('💰 Checkout URL extracted: $checkoutUrl');
          logger.d('Checkout URL type: ${checkoutUrl.runtimeType}');
          logger.d('Checkout URL is null: ${checkoutUrl == null}');
          logger.d('Checkout URL is empty: ${checkoutUrl?.isEmpty ?? true}');
        } else {
          logger.w('⚠️ No payment data in response');
          logger.d('Available keys in orderData: ${orderData.keys.toList()}');
          if (paymentMethod == 'online') {
            logger.e('❌ Online payment selected but no payment data in response!');
          }
        }
        
        // Получаем данные заказа из ответа, если они есть
        final totalAmount = (orderData['total_amount'] as num?)?.toDouble() ?? 0.0;
        final deliveryCost = (orderData['delivery_cost'] as num?)?.toDouble();
        final deliveryMethod = orderData['delivery_method'] as String?;
        final currency = orderData['currency'] as String? ?? 'RUB';
        final status = orderData['status'] as String? ?? 'new';
        final paymentStatus = orderData['payment_status'] as String? ?? 'pending';
        
        final order = entities.Order(
          id: orderId,
          businessId: businessSlug, // Используем slug как идентификатор
          customerName: customerName,
          customerPhone: customerPhone,
          customerAddress: customerAddress,
          totalAmount: totalAmount,
          deliveryCost: deliveryCost,
          deliveryMethod: deliveryMethod,
          currency: currency,
          status: entities.OrderStatus.values.firstWhere(
            (e) => e.toString().split('.').last == status,
            orElse: () => entities.OrderStatus.new_,
          ),
          paymentStatus: entities.PaymentStatus.values.firstWhere(
            (e) => e.toString().split('.').last == paymentStatus,
            orElse: () => entities.PaymentStatus.pending,
          ),
          paymentMethod: paymentMethod == 'online' 
              ? entities.PaymentMethod.online 
              : entities.PaymentMethod.cash,
          // Сохраняем paymentUrl в metadata для передачи в CheckoutBloc
          metadata: checkoutUrl != null ? {'payment_url': checkoutUrl} : null,
          items: (orderData['items'] as List<dynamic>?)
              ?.map((itemJson) => entities.OrderItem(
                    id: itemJson['id'] as String,
                    productId: itemJson['product_id'] as String,
                    titleSnapshot: itemJson['title_snapshot'] as String,
                    quantity: itemJson['quantity'] as int,
                    unitPrice: (itemJson['unit_price'] as num).toDouble(),
                    totalPrice: (itemJson['total_price'] as num).toDouble(),
                  ))
              .toList() ?? [],
          createdAt: DateTime.parse(orderData['created_at'] as String? ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.parse(orderData['updated_at'] as String? ?? DateTime.now().toIso8601String()),
        );
        
        logger.d('Order entity created with metadata: ${order.metadata}');
        logger.d('Order payment method: ${order.paymentMethod}');
        logger.i('✅ Order entity created successfully');
        
        return Right(order);
      }

      return Left(ServerFailure('Неверный формат ответа от сервера'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['detail'] as String? ?? 'Ошибка валидации';
        return Left(ServerFailure(message));
      }
      
      // Улучшенная обработка сетевых ошибок
      String errorMessage = 'Ошибка создания заказа';
      if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Не удалось подключиться к серверу. Проверьте подключение к интернету и убедитесь, что сервер запущен.';
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Превышено время ожидания ответа от сервера. Попробуйте позже.';
      } else if (e.message != null) {
        errorMessage = 'Ошибка создания заказа: ${e.message}';
      }
      
      logger.e('Order creation error: ${e.type}, message: ${e.message}');
      if (e.response != null) {
        logger.e('Response status: ${e.response?.statusCode}, data: ${e.response?.data}');
      }
      
      return Left(ServerFailure(errorMessage));
    } catch (e) {
      logger.e('Unexpected error creating order: $e');
      return Left(ServerFailure('Неожиданная ошибка: $e'));
    }
  }

  @override
  Future<Either<Failure, entities.Order>> getOrder(String orderId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.order(orderId),
      );

      if (response.statusCode == 200) {
        final orderData = response.data;
        final order = _parseOrder(orderData);
        return Right(order);
      }

      return Left(NotFoundFailure('Заказ не найден'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return Left(NotFoundFailure('Заказ не найден'));
      }
      return Left(ServerFailure('Ошибка загрузки заказа: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Ошибка загрузки заказа: $e'));
    }
  }

  @override
  Future<Either<Failure, List<entities.Order>>> getOrders({
    int? telegramId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      if (telegramId == null) {
        return Left(ServerFailure('Telegram ID не указан'));
      }

      final response = await _apiClient.dio.get(
        ApiConstants.userOrders(telegramId),
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final ordersData = response.data as List;
        final orders = ordersData.map((orderData) => _parseOrder(orderData)).toList();
        return Right(orders);
      }

      return Left(ServerFailure('Неверный формат ответа от сервера'));
    } on DioException catch (e) {
      return Left(ServerFailure('Ошибка загрузки заказов: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Ошибка загрузки заказов: $e'));
    }
  }

  entities.Order _parseOrder(Map<String, dynamic> orderData) {
    final itemsData = orderData['items'] as List? ?? [];
    final items = itemsData.map((itemData) {
      return entities.OrderItem(
        id: itemData['id'].toString(),
        productId: itemData['product_id'].toString(),
        titleSnapshot: itemData['title_snapshot'] as String,
        quantity: itemData['quantity'] as int,
        unitPrice: (itemData['unit_price'] as num).toDouble(),
        totalPrice: (itemData['total_price'] as num).toDouble(),
      );
    }).toList();

    return entities.Order(
      id: orderData['id'].toString(),
      businessId: '', // Будет заполнено из контекста
      customerName: orderData['customer_name'] as String,
      customerPhone: orderData['customer_phone'] as String,
      customerAddress: orderData['customer_address'] as String?,
      totalAmount: (orderData['total_amount'] as num).toDouble(),
      deliveryCost: (orderData['delivery_cost'] as num?)?.toDouble(),
      deliveryMethod: orderData['delivery_method'] as String?,
      currency: orderData['currency'] as String? ?? 'RUB',
      status: _parseOrderStatus(orderData['status'] as String),
      paymentStatus: _parsePaymentStatus(orderData['payment_status'] as String),
      paymentMethod: _parsePaymentMethod(orderData['payment_method'] as String),
      items: items,
      createdAt: DateTime.parse(orderData['created_at'] as String),
      updatedAt: DateTime.parse(orderData['updated_at'] as String),
    );
  }

  entities.OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return entities.OrderStatus.new_;
      case 'accepted':
        return entities.OrderStatus.accepted;
      case 'preparing':
        return entities.OrderStatus.preparing;
      case 'ready':
        return entities.OrderStatus.ready;
      case 'cancelled':
        return entities.OrderStatus.cancelled;
      case 'completed':
        return entities.OrderStatus.completed;
      default:
        return entities.OrderStatus.new_;
    }
  }

  entities.PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return entities.PaymentStatus.pending;
      case 'paid':
        return entities.PaymentStatus.paid;
      case 'failed':
        return entities.PaymentStatus.failed;
      case 'refunded':
        return entities.PaymentStatus.refunded;
      default:
        return entities.PaymentStatus.pending;
    }
  }

  entities.PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'online':
        return entities.PaymentMethod.online;
      case 'cash':
      default:
        return entities.PaymentMethod.cash;
    }
  }

  @override
  Future<Either<Failure, entities.Order>> cancelOrder(String orderId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.cancelOrder(orderId),
      );

      if (response.statusCode == 200) {
        final orderData = response.data;
        
        final List<entities.OrderItem> orderItems = (orderData['items'] as List<dynamic>?)
            ?.map((itemJson) => entities.OrderItem(
                  id: itemJson['id'] as String,
                  productId: itemJson['product_id'] as String,
                  titleSnapshot: itemJson['title_snapshot'] as String,
                  quantity: itemJson['quantity'] as int,
                  unitPrice: (itemJson['unit_price'] as num).toDouble(),
                  totalPrice: (itemJson['total_price'] as num).toDouble(),
                ))
            .toList() ?? [];

        final order = entities.Order(
          id: orderData['id'] as String,
          businessId: orderData['business_id'] as String,
          userTelegramId: orderData['user_telegram_id'] as int?,
          customerName: orderData['customer_name'] as String,
          customerPhone: orderData['customer_phone'] as String,
          customerAddress: orderData['customer_address'] as String?,
          totalAmount: (orderData['total_amount'] as num).toDouble(),
          deliveryCost: (orderData['delivery_cost'] as num?)?.toDouble(),
          deliveryMethod: orderData['delivery_method'] as String?,
          currency: orderData['currency'] as String,
          status: entities.OrderStatus.values.firstWhere(
              (e) => e.toString() == 'OrderStatus.${orderData['status']}',
              orElse: () => entities.OrderStatus.new_),
          paymentStatus: entities.PaymentStatus.values.firstWhere(
              (e) => e.toString() == 'PaymentStatus.${orderData['payment_status']}',
              orElse: () => entities.PaymentStatus.pending),
          paymentMethod: entities.PaymentMethod.values.firstWhere(
              (e) => e.toString() == 'PaymentMethod.${orderData['payment_method']}',
              orElse: () => entities.PaymentMethod.cash),
          metadata: orderData['order_metadata'] as Map<String, dynamic>?,
          items: orderItems,
          createdAt: DateTime.parse(orderData['created_at'] as String),
          updatedAt: DateTime.parse(orderData['updated_at'] as String),
        );
        return Right(order);
      }
      return Left(ServerFailure('Неверный формат ответа от сервера'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['detail'] as String? ?? 'Ошибка валидации';
        return Left(ServerFailure(message));
      }
      if (e.response?.statusCode == 404) {
        return Left(NotFoundFailure('Заказ не найден'));
      }
      return Left(ServerFailure('Ошибка отмены заказа: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Ошибка отмены заказа: $e'));
    }
  }
}

