part of 'catalog_bloc.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CatalogEvent {
  final String businessSlug;

  const LoadCategories(this.businessSlug);

  @override
  List<Object?> get props => [businessSlug];
}

class LoadProducts extends CatalogEvent {
  final String businessSlug;
  final double? minPrice;
  final double? maxPrice;

  const LoadProducts(this.businessSlug, {this.minPrice, this.maxPrice});

  @override
  List<Object?> get props => [businessSlug, minPrice, maxPrice];
}

class SearchProducts extends CatalogEvent {
  final String businessSlug;
  final String query;

  const SearchProducts(this.businessSlug, this.query);

  @override
  List<Object?> get props => [businessSlug, query];
}

class FilterByCategory extends CatalogEvent {
  final String businessSlug;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;

  const FilterByCategory(
    this.businessSlug,
    this.categoryId, {
    this.minPrice,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [businessSlug, categoryId, minPrice, maxPrice];
}

class SortProducts extends CatalogEvent {
  final String businessSlug;
  final String sortType; // 'price_asc', 'price_desc', 'popular', 'new', 'all'

  const SortProducts(this.businessSlug, this.sortType);

  @override
  List<Object?> get props => [businessSlug, sortType];
}

