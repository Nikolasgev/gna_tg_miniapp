import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/domain/entities/cart_item.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';
import 'package:tg_store/mini_app/application/services/cart_storage_service.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartStorageService _storageService = CartStorageService();

  CartBloc() : super(CartInitial()) {
    logger.i('CartBloc created');
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<LoadCart>(_onLoadCart);
    on<LoadCartFromStorage>(_onLoadCartFromStorage);
    
    // Загружаем корзину из локального хранилища при инициализации
    add(LoadCartFromStorage());
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    logger.i(
      'AddToCart event: ${event.product.title} x${event.quantity}, variations: ${event.selectedVariations}',
    );
    final currentItems = state.items;
    
    // Логируем все существующие товары с таким же productId
    final sameProductItems = currentItems.where(
      (item) => item.productId == event.product.id,
    ).toList();
    logger.d(
      'Found ${sameProductItems.length} items with same productId: ${sameProductItems.map((item) => 'variations: ${item.selectedVariations}, quantity: ${item.quantity}').join('; ')}',
    );
    
    // Ищем товар с таким же ID и такими же вариациями
    final existingIndex = currentItems.indexWhere(
      (item) => item.productId == event.product.id &&
          _variationsEqual(item.selectedVariations, event.selectedVariations),
    );

    List<CartItem> newItems;
    if (existingIndex >= 0) {
      logger.d(
        'Product already in cart at index $existingIndex, updating quantity. Current variations: ${currentItems[existingIndex].selectedVariations}, new variations: ${event.selectedVariations}',
      );
      newItems = List.from(currentItems);
      newItems[existingIndex] = newItems[existingIndex].copyWith(
        quantity: newItems[existingIndex].quantity + event.quantity,
      );
    } else {
      logger.d(
        'Adding new product to cart with variations: ${event.selectedVariations}',
      );
      newItems = [
        ...currentItems,
        CartItem(
          productId: event.product.id,
          product: event.product,
          quantity: event.quantity,
          note: event.note,
          selectedVariations: event.selectedVariations,
        ),
      ];
    }

    logger.i(
      'Cart updated: ${newItems.length} items, total: ${newItems.fold(0, (sum, item) => sum + item.quantity)}',
    );
    emit(CartLoaded(newItems));
    // Сохраняем корзину в локальное хранилище
    _storageService.saveCart(newItems);
  }

  // Вспомогательный метод для сравнения вариаций
  bool _variationsEqual(Map<String, String>? a, Map<String, String>? b) {
    if (a == null && b == null) {
      logger.d('Both variations are null, equal');
      return true;
    }
    if (a == null || b == null) {
      logger.d('One variation is null, not equal: a=$a, b=$b');
      return false;
    }
    if (a.length != b.length) {
      logger.d('Variations length mismatch: a=${a.length} ($a), b=${b.length} ($b)');
      return false;
    }
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        logger.d(
          'Variations mismatch at key "$key": a="${a[key]}", b="${b.containsKey(key) ? b[key] : 'missing'}"',
        );
        return false;
      }
    }
    logger.d('Variations are equal: $a');
    return true;
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    // Если указаны вариации, удаляем только товар с этими вариациями
    // Иначе удаляем все товары с таким productId (для обратной совместимости)
    final newItems = state.items.where((item) {
      if (event.selectedVariations != null) {
        return !(item.productId == event.productId &&
            _variationsEqual(item.selectedVariations, event.selectedVariations));
      }
      return item.productId != event.productId;
    }).toList();
    emit(CartLoaded(newItems));
    // Сохраняем корзину в локальное хранилище
    _storageService.saveCart(newItems);
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      // При удалении нужно найти товар с учетом вариаций
      add(RemoveFromCart(
        event.productId,
        selectedVariations: event.selectedVariations,
      ));
      return;
    }

    // Обновляем количество товара с учетом вариаций
    final newItems = state.items.map((item) {
      if (item.productId == event.productId &&
          _variationsEqual(item.selectedVariations, event.selectedVariations)) {
        return item.copyWith(quantity: event.quantity);
      }
      return item;
    }).toList();

    emit(CartLoaded(newItems));
    // Сохраняем корзину в локальное хранилище
    _storageService.saveCart(newItems);
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(CartLoaded([]));
    // Очищаем корзину в локальном хранилище
    _storageService.clearCart();
  }

  void _onLoadCart(LoadCart event, Emitter<CartState> emit) {
    emit(CartLoaded(event.items));
    // Сохраняем корзину в локальное хранилище
    _storageService.saveCart(event.items);
  }

  Future<void> _onLoadCartFromStorage(
    LoadCartFromStorage event,
    Emitter<CartState> emit,
  ) async {
    logger.i('Loading cart from storage');
    final items = await _storageService.loadCart();
    if (items.isNotEmpty) {
      logger.i('Loaded ${items.length} items from storage');
      emit(CartLoaded(items));
    } else {
      logger.i('No items found in storage');
    }
  }
}

