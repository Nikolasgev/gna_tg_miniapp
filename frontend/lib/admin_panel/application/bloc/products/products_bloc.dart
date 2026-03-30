import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart' show logger;
import 'package:tg_store/admin_panel/domain/repositories/products_repository.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductsRepository productsRepository;

  ProductsBloc({required this.productsRepository}) : super(ProductsInitial()) {
    logger.i('ProductsBloc created');

    on<LoadProducts>(_onLoadProducts);
    on<SearchProducts>(_onSearchProducts);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByStatus>(_onFilterByStatus);
    on<LoadProduct>(_onLoadProduct);
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  void _onLoadProducts(LoadProducts event, Emitter<ProductsState> emit) async {
    logger.d('LoadProducts event: businessSlug=${event.businessSlug}');
    emit(ProductsLoading());

    final result = await productsRepository.getProducts(
      businessSlug: event.businessSlug,
      searchQuery: event.searchQuery,
      categoryId: event.categoryId,
      includeInactive: event.includeInactive,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load products: ${failure.message}');
        emit(ProductsError(failure.message));
      },
      (products) {
        logger.i('Loaded ${products.length} products');
        emit(ProductsLoaded(
          products: products,
          searchQuery: event.searchQuery ?? '',
          selectedCategoryId: event.categoryId,
          filterActive: event.includeInactive == null ? null : !event.includeInactive!,
        ));
      },
    );
  }

  void _onSearchProducts(SearchProducts event, Emitter<ProductsState> emit) async {
    logger.d('SearchProducts event: query=${event.query}');
    
    final currentState = state;
    if (currentState is ProductsLoaded) {
      emit(ProductsLoading());
    }

    final result = await productsRepository.getProducts(
      businessSlug: event.businessSlug,
      searchQuery: event.query.isEmpty ? null : event.query,
      categoryId: currentState is ProductsLoaded ? currentState.selectedCategoryId : null,
      includeInactive: currentState is ProductsLoaded 
          ? (currentState.filterActive == null ? null : !currentState.filterActive!)
          : true,
    );

    result.fold(
      (failure) {
        logger.e('Failed to search products: ${failure.message}');
        emit(ProductsError(failure.message));
      },
      (products) {
        logger.i('Found ${products.length} products');
        emit(ProductsLoaded(
          products: products,
          searchQuery: event.query,
          selectedCategoryId: currentState is ProductsLoaded ? currentState.selectedCategoryId : null,
          filterActive: currentState is ProductsLoaded ? currentState.filterActive : null,
        ));
      },
    );
  }

  void _onFilterByCategory(FilterByCategory event, Emitter<ProductsState> emit) async {
    logger.i('FilterByCategory event: categoryId=${event.categoryId}');
    
    final currentState = state;
    if (currentState is ProductsLoaded) {
      emit(ProductsLoading());
    }

    final result = await productsRepository.getProducts(
      businessSlug: event.businessSlug,
      searchQuery: currentState is ProductsLoaded ? currentState.searchQuery : null,
      categoryId: event.categoryId,
      includeInactive: currentState is ProductsLoaded 
          ? (currentState.filterActive == null ? null : !currentState.filterActive!)
          : true,
    );

    result.fold(
      (failure) {
        logger.e('Failed to filter products: ${failure.message}');
        emit(ProductsError(failure.message));
      },
      (products) {
        logger.i('Filtered ${products.length} products');
        emit(ProductsLoaded(
          products: products,
          searchQuery: currentState is ProductsLoaded ? currentState.searchQuery : '',
          selectedCategoryId: event.categoryId,
          filterActive: currentState is ProductsLoaded ? currentState.filterActive : null,
        ));
      },
    );
  }

  void _onFilterByStatus(FilterByStatus event, Emitter<ProductsState> emit) async {
    logger.i('FilterByStatus event: filterActive=${event.filterActive}');
    
    final currentState = state;
    if (currentState is ProductsLoaded) {
      emit(ProductsLoading());
    }

    final result = await productsRepository.getProducts(
      businessSlug: event.businessSlug,
      searchQuery: currentState is ProductsLoaded ? currentState.searchQuery : null,
      categoryId: currentState is ProductsLoaded ? currentState.selectedCategoryId : null,
      includeInactive: event.filterActive == null ? null : !event.filterActive!,
    );

    result.fold(
      (failure) {
        logger.e('Failed to filter products by status: ${failure.message}');
        emit(ProductsError(failure.message));
      },
      (products) {
        logger.i('Filtered ${products.length} products by status');
        emit(ProductsLoaded(
          products: products,
          searchQuery: currentState is ProductsLoaded ? currentState.searchQuery : '',
          selectedCategoryId: currentState is ProductsLoaded ? currentState.selectedCategoryId : null,
          filterActive: event.filterActive,
        ));
      },
    );
  }

  void _onLoadProduct(LoadProduct event, Emitter<ProductsState> emit) async {
    logger.i('LoadProduct event: productId=${event.productId}');
    emit(ProductLoading());

    final result = await productsRepository.getProduct(
      businessSlug: event.businessSlug,
      productId: event.productId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to load product: ${failure.message}');
        emit(ProductError(failure.message));
      },
      (product) {
        logger.i('Product loaded: ${product['title']}');
        emit(ProductLoaded(product));
      },
    );
  }

  void _onCreateProduct(CreateProduct event, Emitter<ProductsState> emit) async {
    logger.i('CreateProduct event');
    emit(ProductSaving());

    final result = await productsRepository.createProduct(
      businessSlug: event.businessSlug,
      productData: event.productData,
    );

    result.fold(
      (failure) {
        logger.e('Failed to create product: ${failure.message}');
        emit(ProductError(failure.message));
      },
      (product) {
        logger.i('Product created: ${product['title']}');
        emit(ProductCreated(product));
        // Перезагружаем список товаров
        add(LoadProducts(event.businessSlug, includeInactive: true));
      },
    );
  }

  void _onUpdateProduct(UpdateProduct event, Emitter<ProductsState> emit) async {
    logger.i('UpdateProduct event: productId=${event.productId}');
    emit(ProductSaving());

    final result = await productsRepository.updateProduct(
      businessSlug: event.businessSlug,
      productId: event.productId,
      productData: event.productData,
    );

    result.fold(
      (failure) {
        logger.e('Failed to update product: ${failure.message}');
        emit(ProductError(failure.message));
      },
      (product) {
        logger.i('Product updated: ${product['title']}');
        emit(ProductUpdated(product));
        // Перезагружаем список товаров
        add(LoadProducts(event.businessSlug, includeInactive: true));
      },
    );
  }

  void _onDeleteProduct(DeleteProduct event, Emitter<ProductsState> emit) async {
    logger.i('DeleteProduct event: productId=${event.productId}');
    emit(ProductDeleting());

    final result = await productsRepository.deleteProduct(
      businessSlug: event.businessSlug,
      productId: event.productId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to delete product: ${failure.message}');
        emit(ProductError(failure.message));
      },
      (_) {
        logger.i('Product deleted: ${event.productId}');
        emit(ProductDeleted());
        // Перезагружаем список товаров
        add(LoadProducts(event.businessSlug, includeInactive: true));
      },
    );
  }
}

