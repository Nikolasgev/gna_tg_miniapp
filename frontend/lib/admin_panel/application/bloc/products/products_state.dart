part of 'products_bloc.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Map<String, dynamic>> products;
  final String searchQuery;
  final String? selectedCategoryId;
  final bool? filterActive; // null = все, true = только активные, false = только неактивные

  const ProductsLoaded({
    required this.products,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.filterActive,
  });

  @override
  List<Object?> get props => [products, searchQuery, selectedCategoryId, filterActive];
}

class ProductsError extends ProductsState {
  final String message;

  const ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Состояния для работы с одним товаром
class ProductLoading extends ProductsState {}

class ProductLoaded extends ProductsState {
  final Map<String, dynamic> product;

  const ProductLoaded(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductSaving extends ProductsState {}

class ProductCreated extends ProductsState {
  final Map<String, dynamic> product;

  const ProductCreated(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductUpdated extends ProductsState {
  final Map<String, dynamic> product;

  const ProductUpdated(this.product);

  @override
  List<Object?> get props => [product];
}

class ProductDeleting extends ProductsState {}

class ProductDeleted extends ProductsState {}

class ProductError extends ProductsState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

