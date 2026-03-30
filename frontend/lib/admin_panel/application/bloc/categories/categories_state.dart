part of 'categories_bloc.dart';

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final List<Map<String, dynamic>> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class CategoriesError extends CategoriesState {
  final String message;

  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Состояния для работы с одной категорией
class CategoryLoading extends CategoriesState {}

class CategoryLoaded extends CategoriesState {
  final Map<String, dynamic> category;

  const CategoryLoaded(this.category);

  @override
  List<Object?> get props => [category];
}

class CategorySaving extends CategoriesState {}

class CategoryCreated extends CategoriesState {
  final Map<String, dynamic> category;

  const CategoryCreated(this.category);

  @override
  List<Object?> get props => [category];
}

class CategoryUpdated extends CategoriesState {
  final Map<String, dynamic> category;

  const CategoryUpdated(this.category);

  @override
  List<Object?> get props => [category];
}

class CategoryDeleting extends CategoriesState {}

class CategoryDeleted extends CategoriesState {}

class CategoryError extends CategoriesState {
  final String message;

  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}

