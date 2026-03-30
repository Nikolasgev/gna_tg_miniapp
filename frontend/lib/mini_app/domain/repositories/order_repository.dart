import 'package:dartz/dartz.dart';
import 'package:tg_store/core/error/failures.dart';
import 'package:tg_store/mini_app/domain/entities/order.dart' as entities;

abstract class OrderRepository {
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
  });
  
  Future<Either<Failure, entities.Order>> getOrder(String orderId);
  
  Future<Either<Failure, List<entities.Order>>> getOrders({
    int? telegramId,
    int page = 1,
    int limit = 20,
  });
  
  Future<Either<Failure, entities.Order>> cancelOrder(String orderId);
}

