part of 'products_bloc.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {
  final String businessSlug;
  final String? searchQuery;
  final String? categoryId;
  final bool? includeInactive;

  const LoadProducts(
    this.businessSlug, {
    this.searchQuery,
    this.categoryId,
    this.includeInactive,
  });

  @override
  List<Object?> get props => [businessSlug, searchQuery, categoryId, includeInactive];
}

class SearchProducts extends ProductsEvent {
  final String businessSlug;
  final String query;

  const SearchProducts(this.businessSlug, this.query);

  @override
  List<Object?> get props => [businessSlug, query];
}

class FilterByCategory extends ProductsEvent {
  final String businessSlug;
  final String? categoryId;

  const FilterByCategory(this.businessSlug, this.categoryId);

  @override
  List<Object?> get props => [businessSlug, categoryId];
}

class FilterByStatus extends ProductsEvent {
  final String businessSlug;
  final bool? filterActive; // null = все, true = только активные, false = только неактивные

  const FilterByStatus(this.businessSlug, this.filterActive);

  @override
  List<Object?> get props => [businessSlug, filterActive];
}

class LoadProduct extends ProductsEvent {
  final String businessSlug;
  final String productId;

  const LoadProduct(this.businessSlug, this.productId);

  @override
  List<Object?> get props => [businessSlug, productId];
}

class CreateProduct extends ProductsEvent {
  final String businessSlug;
  final Map<String, dynamic> productData;

  const CreateProduct(this.businessSlug, this.productData);

  @override
  List<Object?> get props => [businessSlug, productData];
}

class UpdateProduct extends ProductsEvent {
  final String businessSlug;
  final String productId;
  final Map<String, dynamic> productData;

  const UpdateProduct(this.businessSlug, this.productId, this.productData);

  @override
  List<Object?> get props => [businessSlug, productId, productData];
}

class DeleteProduct extends ProductsEvent {
  final String businessSlug;
  final String productId;

  const DeleteProduct(this.businessSlug, this.productId);

  @override
  List<Object?> get props => [businessSlug, productId];
}

