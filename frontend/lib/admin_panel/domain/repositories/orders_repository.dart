import 'package:dartz/dartz.dart';
import 'package:tg_store/core/error/failures.dart';

/// Интерфейс репозитория для работы с заказами в админ-панели
abstract class OrdersRepository {
  /// Получить список заказов
  Future<Either<Failure, List<Map<String, dynamic>>>> getOrders({
    required String businessSlug,
    int page = 1,
    int limit = 20,
  });

  /// Получить заказ по ID
  Future<Either<Failure, Map<String, dynamic>>> getOrder({
    required String businessSlug,
    required String orderId,
  });

  /// Обновить статус заказа
  Future<Either<Failure, Map<String, dynamic>>> updateOrderStatus({
    required String businessSlug,
    required String orderId,
    required String status,
    String? paymentStatus,
  });
}

