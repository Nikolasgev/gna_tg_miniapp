import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/admin_panel/domain/repositories/categories_repository.dart';

part 'categories_event.dart';
part 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesRepository categoriesRepository;

  CategoriesBloc({required this.categoriesRepository}) : super(CategoriesInitial()) {
    logger.i('CategoriesBloc created');

    on<LoadCategories>(_onLoadCategories);
    on<LoadCategory>(_onLoadCategory);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  void _onLoadCategories(LoadCategories event, Emitter<CategoriesState> emit) async {
    logger.i('LoadCategories event: businessSlug=${event.businessSlug}');
    emit(CategoriesLoading());

    final result = await categoriesRepository.getCategories(businessSlug: event.businessSlug);

    result.fold(
      (failure) {
        logger.e('Failed to load categories: ${failure.message}');
        emit(CategoriesError(failure.message));
      },
      (categories) {
        logger.i('Loaded ${categories.length} categories');
        emit(CategoriesLoaded(categories));
      },
    );
  }

  void _onLoadCategory(LoadCategory event, Emitter<CategoriesState> emit) async {
    logger.i('LoadCategory event: categoryId=${event.categoryId}');
    emit(CategoryLoading());

    final result = await categoriesRepository.getCategory(
      businessSlug: event.businessSlug,
      categoryId: event.categoryId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load category: ${failure.message}');
        emit(CategoryError(failure.message));
      },
      (category) {
        logger.i('Category loaded: ${category['name']}');
        emit(CategoryLoaded(category));
      },
    );
  }

  void _onCreateCategory(CreateCategory event, Emitter<CategoriesState> emit) async {
    logger.i('CreateCategory event');
    emit(CategorySaving());

    final result = await categoriesRepository.createCategory(
      businessSlug: event.businessSlug,
      categoryData: event.categoryData,
    );

    result.fold(
      (failure) {
        logger.e('Failed to create category: ${failure.message}');
        emit(CategoryError(failure.message));
      },
      (category) {
        logger.i('Category created: ${category['name']}');
        emit(CategoryCreated(category));
        add(LoadCategories(event.businessSlug));
      },
    );
  }

  void _onUpdateCategory(UpdateCategory event, Emitter<CategoriesState> emit) async {
    logger.i('UpdateCategory event: categoryId=${event.categoryId}');
    emit(CategorySaving());

    final result = await categoriesRepository.updateCategory(
      businessSlug: event.businessSlug,
      categoryId: event.categoryId,
      categoryData: event.categoryData,
    );

    result.fold(
      (failure) {
        logger.e('Failed to update category: ${failure.message}');
        emit(CategoryError(failure.message));
      },
      (category) {
        logger.i('Category updated: ${category['name']}');
        emit(CategoryUpdated(category));
        add(LoadCategories(event.businessSlug));
      },
    );
  }

  void _onDeleteCategory(DeleteCategory event, Emitter<CategoriesState> emit) async {
    logger.i('DeleteCategory event: categoryId=${event.categoryId}');
    emit(CategoryDeleting());

    final result = await categoriesRepository.deleteCategory(
      businessSlug: event.businessSlug,
      categoryId: event.categoryId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to delete category: ${failure.message}');
        emit(CategoryError(failure.message));
      },
      (_) {
        logger.i('Category deleted: ${event.categoryId}');
        emit(CategoryDeleted());
        add(LoadCategories(event.businessSlug));
      },
    );
  }
}

