import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';
import 'package:tg_store/mini_app/domain/repositories/catalog_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final CatalogRepository catalogRepository;

  ProductBloc({required this.catalogRepository}) : super(ProductInitial()) {
    on<LoadProduct>(_onLoadProduct);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<IncrementQuantity>(_onIncrementQuantity);
    on<DecrementQuantity>(_onDecrementQuantity);
  }

  void _onLoadProduct(LoadProduct event, Emitter<ProductState> emit) async {
    logger.i('LoadProduct event: productId=${event.productId}');
    emit(ProductLoading());
    
    try {
      final result = await catalogRepository.getProduct(event.productId);
      
      result.fold(
        (failure) {
          logger.e('Failed to load product: ${failure.message}');
          emit(ProductError('Товар не найден: ${failure.message}'));
        },
        (product) {
          logger.i('Product loaded: ${product.title}');
          emit(ProductLoaded(product, quantity: 1));
        },
      );
    } catch (e) {
      logger.e('Error loading product');
      emit(ProductError('Ошибка загрузки товара: $e'));
    }
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<ProductState> emit) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      final newQuantity = event.quantity > 0 ? event.quantity : 1;
      logger.i('UpdateQuantity: $newQuantity');
      emit(ProductLoaded(currentState.product, quantity: newQuantity));
    }
  }

  void _onIncrementQuantity(IncrementQuantity event, Emitter<ProductState> emit) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      logger.i('IncrementQuantity: ${currentState.quantity + 1}');
      emit(ProductLoaded(currentState.product, quantity: currentState.quantity + 1));
    }
  }

  void _onDecrementQuantity(DecrementQuantity event, Emitter<ProductState> emit) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      final newQuantity = currentState.quantity > 1 ? currentState.quantity - 1 : 1;
      logger.i('DecrementQuantity: $newQuantity');
      emit(ProductLoaded(currentState.product, quantity: newQuantity));
    }
  }
}

