import 'package:flutter/material.dart';
import 'package:tg_store/core/utils/logger.dart' show logger;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';
import 'package:tg_store/mini_app/domain/entities/cart_item.dart';
import 'package:tg_store/mini_app/presentation/bloc/cart/cart_bloc.dart';

class AnimatedCartButton extends StatefulWidget {
  final Product product;
  final Map<String, String>? selectedVariations;

  const AnimatedCartButton({
    super.key,
    required this.product,
    this.selectedVariations,
  });

  @override
  State<AnimatedCartButton> createState() => _AnimatedCartButtonState();
}

class _AnimatedCartButtonState extends State<AnimatedCartButton>
    with SingleTickerProviderStateMixin {
  static const double _buttonSize = 48.0; // Размер кнопок плюса и минуса
  
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  int _displayQuantity = 0; // Количество для отображения

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Анимация расширения от 0 до 1
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // Инициализация: если товар уже в корзине, устанавливаем состояние
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateQuantityFromCart();
    });
  }

  @override
  void didUpdateWidget(AnimatedCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если изменились вариации, сбрасываем счетчик и обновляем количество из корзины
    final variationsChanged = !_variationsEqual(oldWidget.selectedVariations, widget.selectedVariations);
    logger.d('🔄 [AnimatedCartButton] didUpdateWidget: variationsChanged=$variationsChanged, old=${oldWidget.selectedVariations}, new=${widget.selectedVariations}');
    
    if (variationsChanged) {
      logger.d('🔄 [AnimatedCartButton] Variations changed, resetting counter');
      // Сбрасываем счетчик и анимацию немедленно
      setState(() {
        _displayQuantity = 0;
        _controller.value = 0.0; // Сбрасываем анимацию
      });
      // Затем обновляем из корзины
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateQuantityFromCart();
        }
      });
    }
  }

  void _updateQuantityFromCart() {
    if (!mounted) return;
    final cartState = context.read<CartBloc>().state;
    final quantity = _getQuantity(cartState);
    logger.d('📊 [AnimatedCartButton] Updating quantity from cart: $quantity for variations: ${widget.selectedVariations}');
    if (quantity > 0) {
      setState(() {
        _displayQuantity = quantity;
        _controller.value = 1.0; // Устанавливаем в развернутое состояние
      });
    } else {
      setState(() {
        _displayQuantity = 0;
        _controller.value = 0.0; // Сбрасываем состояние
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getQuantity(CartState state) {
    if (state is CartLoaded) {
      // Ищем товар с таким же ID и такими же вариациями
      final item = state.items.firstWhere(
        (item) => item.productId == widget.product.id &&
            _variationsEqual(item.selectedVariations, widget.selectedVariations),
        orElse: () => CartItem(
          productId: widget.product.id,
          product: widget.product,
          quantity: 0,
          selectedVariations: widget.selectedVariations,
        ),
      );
      return item.quantity;
    }
    return 0;
  }
  
  // Вспомогательный метод для сравнения вариаций
  bool _variationsEqual(Map<String, String>? a, Map<String, String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  void _onAddToCart() {
    // Проверяем наличие товара
    if (!widget.product.isInStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Товар "${widget.product.title}" отсутствует на складе'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Обновляем количество для отображения сразу
    setState(() {
      _displayQuantity = 1;
    });
    
    // Запускаем анимацию расширения
    _controller.forward();
    
    // Добавляем товар в корзину
    context.read<CartBloc>().add(
          AddToCart(
            product: widget.product,
            quantity: 1,
            selectedVariations: widget.selectedVariations,
          ),
        );
    
    // Показываем уведомление о добавлении в корзину
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.selectedVariations != null && widget.selectedVariations!.isNotEmpty
              ? '${widget.product.title} добавлен в корзину'
              : '${widget.product.title} добавлен в корзину',
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'В корзину',
          onPressed: () {
            // Можно добавить навигацию в корзину
          },
        ),
      ),
    );
  }

  void _onIncrement() {
    final cartState = context.read<CartBloc>().state;
    final currentQuantity = _getQuantity(cartState);
    
    // Проверяем наличие товара и ограничение по количеству
    if (!widget.product.isInStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Товар "${widget.product.title}" отсутствует на складе'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Проверяем, не превышает ли новое количество доступное количество на складе
    if (widget.product.stockQuantity != null) {
      final availableQuantity = widget.product.stockQuantity!;
      if (currentQuantity >= availableQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Доступно только $availableQuantity шт. товара "${widget.product.title}"'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    
    setState(() {
      _displayQuantity = currentQuantity + 1;
    });
    
    context.read<CartBloc>().add(
          AddToCart(
            product: widget.product,
            quantity: 1,
            selectedVariations: widget.selectedVariations,
          ),
        );
  }

  void _onDecrement() {
    final cartState = context.read<CartBloc>().state;
    final currentQuantity = _getQuantity(cartState);
    
    if (currentQuantity > 1) {
      // Просто уменьшаем количество
      setState(() {
        _displayQuantity = currentQuantity - 1;
      });
      context.read<CartBloc>().add(
            UpdateQuantity(
              productId: widget.product.id,
              quantity: currentQuantity - 1,
              selectedVariations: widget.selectedVariations,
            ),
          );
    } else {
      // Запускаем анимацию слияния
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() {
            _displayQuantity = 0;
          });
          // Удаляем товар с учетом вариаций
          context.read<CartBloc>().add(
                RemoveFromCart(
                  widget.product.id,
                  selectedVariations: widget.selectedVariations,
                ),
              );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, cartState) {
        final quantity = _getQuantity(cartState);
        
        // Синхронизируем отображаемое количество, если анимация не идет
        if (_controller.status != AnimationStatus.forward &&
            _controller.status != AnimationStatus.reverse) {
          if (quantity != _displayQuantity) {
            setState(() {
              _displayQuantity = quantity;
            });
            
            // Если товар добавлен, но виджет не развернут - разворачиваем
            if (quantity > 0 && _controller.value == 0.0) {
              _controller.forward();
            }
            // Если товар удален, но виджет развернут - сворачиваем
            else if (quantity == 0 && _controller.value == 1.0) {
              _controller.reverse();
            }
          }
        }
      },
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final quantity = _getQuantity(cartState);
          
          // Используем отображаемое количество во время анимации
          final displayQty = (_controller.status == AnimationStatus.forward ||
                            _controller.status == AnimationStatus.reverse)
              ? _displayQuantity
              : quantity;

          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              final progress = _expandAnimation.value;
              final isReversing = _controller.status == AnimationStatus.reverse;
              
              // Показываем компактную кнопку только если:
              // 1. При прямой анимации: progress < 0.3 (еще не развернулся)
              // 2. При обратной анимации: progress <= 0 (анимация полностью завершена)
              // Это предотвращает эффект сужения виджета при обратной анимации
              if ((!isReversing && progress < 0.3) || (isReversing && progress <= 0.0)) {
                final isDisabled = !widget.product.isInStock;
                return SizedBox(
                  width: _buttonSize,
                  height: _buttonSize,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isDisabled ? null : _onAddToCart,
                    child: Container(
                      width: _buttonSize,
                      height: _buttonSize,
                      decoration: BoxDecoration(
                        color: isDisabled 
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                                child: Icon(
                                  Icons.add,
                        color: isDisabled
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.38)
                            : Theme.of(context).colorScheme.onPrimary,
                                  size: 24,
                                ),
                    ),
                  ),
                );
              }
              
              // Иначе показываем расширенный виджет
              // При прямой анимации: от 40 до 120 (уменьшено для более компактного вида)
              // При обратной анимации: ширина остается 120 (не уменьшаем, чтобы избежать двойной анимации)
              // Кривая уже применена в _expandAnimation, используем progress напрямую
              final width = isReversing
                  ? 120.0 // Фиксированная ширина при обратной анимации (уменьшено с 148)
                  : 40 + (progress - 0.3) / 0.7 * 72; // Максимальная ширина 120 вместо 148
              
              // Прозрачность и появление элементов при прямой анимации
              final elementOpacity = isReversing
                  ? (progress >= 0.3 ? (progress - 0.3) / 0.7 : 0.0).clamp(0.0, 1.0)
                  : ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
              
              // Масштаб кнопок при прямой анимации
              final buttonScale = isReversing
                  ? (progress >= 0.3 ? (progress - 0.3) / 0.7 : 0.0).clamp(0.0, 1.0)
                  : ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
              
              // Прозрачность количества
              // При прямой анимации: появляется после 0.5
              // При обратной анимации: исчезает плавно
              final quantityOpacity = isReversing
                  ? progress.clamp(0.0, 1.0) // Плавно исчезает от 1.0 до 0.0
                  : ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
              
              // Вычисляем позиции относительно центра для горизонтального выравнивания
              final centerX = width / 2;
              final buttonWidth = _buttonSize;
              final buttonHalfWidth = buttonWidth / 2;
              
              // Расстояние между центрами кнопок при максимальной ширине (120)
              // При ширине 120: левая кнопка центр = 20, правая кнопка центр = 100, расстояние = 80
              // При ширине 40: обе кнопки в центре = 20
              final maxDistance = 80.0; // Расстояние между центрами кнопок при ширине 120
              final currentDistance = isReversing 
                  ? maxDistance 
                  : (progress - 0.3) / 0.7 * maxDistance; // От 0 до maxDistance
              
              // Смещение кнопки минуса при обратной анимации
              // При обратной анимации: кнопка минуса движется вправо к позиции плюса
              // progress идет от 1.0 к 0.0, поэтому (1.0 - progress) идет от 0.0 к 1.0
              final minButtonOffsetX = isReversing
                  ? (1.0 - progress) * maxDistance // Движется от 0 до maxDistance (вправо)
                  : 0.0;
              
              // Позиции кнопок относительно центра
              // При обратной анимации кнопка минус движется вправо (увеличивается offset)
              final minButtonCenterX = centerX - currentDistance / 2 + minButtonOffsetX;
              final plusButtonCenterX = centerX + currentDistance / 2;
              
              // Прозрачность кнопки минуса при обратной анимации (исчезает плавно в конце)
              // При обратной анимации progress идет от 1.0 к 0.0
              // Исчезает плавно в последние 35% анимации (когда progress < 0.35)
              // Синхронизировано с движением - начинает исчезать когда почти достигла плюса
              final minButtonOpacity = isReversing
                  ? (progress >= 0.35 
                      ? 1.0 
                      : Curves.easeOutCubic.transform(progress / 0.35)).clamp(0.0, 1.0)
                  : elementOpacity;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Блокируем клики в области кнопки, чтобы они не проходили сквозь
                },
                child: SizedBox(
                  width: width,
                  height: _buttonSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Кнопка минус - движется при обратной анимации, выровнена по центру
                      Positioned(
                        left: minButtonCenterX - buttonHalfWidth,
                        top: 0, // Выравнивание по вертикали
                        child: Transform.scale(
                          scale: isReversing ? 1.0 : buttonScale,
                          child: Opacity(
                            opacity: minButtonOpacity,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _onDecrement,
                              child: Container(
                                width: _buttonSize,
                                height: _buttonSize,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Количество в центре
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Opacity(
                            opacity: quantityOpacity,
                            child: Text(
                              displayQty.toString(),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      // Кнопка плюс - выровнена по центру, полностью статична (без анимаций)
                      Positioned(
                        left: plusButtonCenterX - buttonHalfWidth,
                        top: 0, // Выравнивание по вертикали
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _onIncrement,
                          child: Builder(
                            builder: (context) {
                              final isDisabled = !widget.product.isInStock || 
                                  (widget.product.stockQuantity != null && 
                                   displayQty >= widget.product.stockQuantity!);
                              return Container(
                            width: _buttonSize,
                            height: _buttonSize,
                            decoration: BoxDecoration(
                                  color: isDisabled
                                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                                      : Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                                  color: isDisabled
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.38)
                                      : Theme.of(context).colorScheme.onPrimary,
                              size: 20,
                            ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

