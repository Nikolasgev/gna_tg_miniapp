part of 'catalog_bloc.dart';

abstract class CatalogState extends Equatable {
  const CatalogState();

  /// Возвращает список продуктов, если они доступны в состоянии
  List<Product>? get products {
    if (this is CatalogProductsLoaded) {
      return (this as CatalogProductsLoaded).products;
    } else if (this is CatalogLoaded) {
      return (this as CatalogLoaded).products;
    } else if (this is CatalogLoading) {
      return (this as CatalogLoading).products;
    } else if (this is CatalogCategoriesLoaded) {
      return (this as CatalogCategoriesLoaded).products;
    }
    return null;
  }

  /// Возвращает список категорий, если они доступны в состоянии
  List<Category>? get categories {
    if (this is CatalogCategoriesLoaded) {
      return (this as CatalogCategoriesLoaded).categories;
    } else if (this is CatalogLoaded) {
      return (this as CatalogLoaded).categories;
    } else if (this is CatalogLoading) {
      return (this as CatalogLoading).categories;
    } else if (this is CatalogProductsLoaded) {
      return (this as CatalogProductsLoaded).categories;
    }
    return null;
  }

  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {
  @override
  final List<Category>? categories;
  @override
  final List<Product>? products;

  const CatalogLoading({this.categories, this.products});

  @override
  List<Object?> get props => [categories, products];
}

class CatalogCategoriesLoaded extends CatalogState {
  @override
  final List<Category> categories;
  @override
  final List<Product>? products;
  final String searchQuery;
  final String? selectedCategoryId;
  final double? minPrice;
  final double? maxPrice;

  const CatalogCategoriesLoaded(
    this.categories, {
    this.products,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [categories, products, searchQuery, selectedCategoryId, minPrice, maxPrice];
}

class CatalogProductsLoaded extends CatalogState {
  @override
  final List<Product> products;
  @override
  final List<Category>? categories;
  final String searchQuery;
  final String? selectedCategoryId;
  final double? minPrice;
  final double? maxPrice;

  const CatalogProductsLoaded(
    this.products, {
    this.categories,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [products, categories, searchQuery, selectedCategoryId, minPrice, maxPrice];
}

class CatalogLoaded extends CatalogState {
  @override
  final List<Category> categories;
  @override
  final List<Product> products;
  final String searchQuery;
  final String? selectedCategoryId;
  final double? minPrice;
  final double? maxPrice;

  const CatalogLoaded({
    required this.categories,
    required this.products,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [categories, products, searchQuery, selectedCategoryId, minPrice, maxPrice];
}

class CatalogError extends CatalogState {
  final String message;

  const CatalogError(this.message);

  @override
  List<Object?> get props => [message];
}

