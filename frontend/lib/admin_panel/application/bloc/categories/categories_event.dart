part of 'categories_bloc.dart';

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoriesEvent {
  final String businessSlug;

  const LoadCategories(this.businessSlug);

  @override
  List<Object?> get props => [businessSlug];
}

class LoadCategory extends CategoriesEvent {
  final String businessSlug;
  final String categoryId;

  const LoadCategory(this.businessSlug, this.categoryId);

  @override
  List<Object?> get props => [businessSlug, categoryId];
}

class CreateCategory extends CategoriesEvent {
  final String businessSlug;
  final Map<String, dynamic> categoryData;

  const CreateCategory(this.businessSlug, this.categoryData);

  @override
  List<Object?> get props => [businessSlug, categoryData];
}

class UpdateCategory extends CategoriesEvent {
  final String businessSlug;
  final String categoryId;
  final Map<String, dynamic> categoryData;

  const UpdateCategory(this.businessSlug, this.categoryId, this.categoryData);

  @override
  List<Object?> get props => [businessSlug, categoryId, categoryData];
}

class DeleteCategory extends CategoriesEvent {
  final String businessSlug;
  final String categoryId;

  const DeleteCategory(this.businessSlug, this.categoryId);

  @override
  List<Object?> get props => [businessSlug, categoryId];
}

