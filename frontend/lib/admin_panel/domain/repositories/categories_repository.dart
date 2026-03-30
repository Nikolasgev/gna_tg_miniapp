import 'package:dartz/dartz.dart';
import 'package:tg_store/core/error/failures.dart';

/// Интерфейс репозитория для работы с категориями в админ-панели
abstract class CategoriesRepository {
  /// Получить список категорий
  Future<Either<Failure, List<Map<String, dynamic>>>> getCategories({
    required String businessSlug,
  });

  /// Получить категорию по ID
  Future<Either<Failure, Map<String, dynamic>>> getCategory({
    required String businessSlug,
    required String categoryId,
  });

  /// Создать категорию
  Future<Either<Failure, Map<String, dynamic>>> createCategory({
    required String businessSlug,
    required Map<String, dynamic> categoryData,
  });

  /// Обновить категорию
  Future<Either<Failure, Map<String, dynamic>>> updateCategory({
    required String businessSlug,
    required String categoryId,
    required Map<String, dynamic> categoryData,
  });

  /// Удалить категорию
  Future<Either<Failure, void>> deleteCategory({
    required String businessSlug,
    required String categoryId,
  });
}

