import 'package:dartz/dartz.dart';
import 'package:tg_store/core/error/failures.dart';

/// Интерфейс репозитория для работы с товарами в админ-панели
abstract class ProductsRepository {
  /// Получить список товаров
  Future<Either<Failure, List<Map<String, dynamic>>>> getProducts({
    required String businessSlug,
    String? searchQuery,
    String? categoryId,
    bool? includeInactive,
  });

  /// Получить товар по ID
  Future<Either<Failure, Map<String, dynamic>>> getProduct({
    required String businessSlug,
    required String productId,
  });

  /// Создать товар
  Future<Either<Failure, Map<String, dynamic>>> createProduct({
    required String businessSlug,
    required Map<String, dynamic> productData,
  });

  /// Обновить товар
  Future<Either<Failure, Map<String, dynamic>>> updateProduct({
    required String businessSlug,
    required String productId,
    required Map<String, dynamic> productData,
  });

  /// Удалить товар
  Future<Either<Failure, void>> deleteProduct({
    required String businessSlug,
    required String productId,
  });
}

