import 'package:tg_store/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:tg_store/mini_app/domain/entities/category.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';

abstract class CatalogRepository {
  Future<Either<Failure, List<Category>>> getCategories(String businessSlug);
  
  Future<Either<Failure, List<Product>>> getProducts({
    required String businessSlug,
    String? categoryId,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  });
  
  Future<Either<Failure, Product>> getProduct(String productId);
}

