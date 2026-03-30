import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';
import 'package:tg_store/mini_app/presentation/bloc/product/product_bloc.dart';
import 'package:tg_store/mini_app/presentation/widgets/animated_cart_button.dart';
import 'package:tg_store/mini_app/presentation/bloc/cart/cart_bloc.dart';
import 'package:tg_store/mini_app/presentation/navigation/app_router.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // Выбранные вариации для каждой категории
  final Map<String, String> _selectedVariations = {};

  @override
  void initState() {
    super.initState();
    logger.i(
      'ProductDetailScreen initState: productId=${widget.productId}',
    );
    context.read<ProductBloc>().add(LoadProduct(widget.productId));
  }

  
  Widget _buildVariationsSelector(Product product) {
    if (product.variations == null || product.variations!.isEmpty) {
      return const SizedBox.shrink();
    }

    final variations = product.variations as Map<String, dynamic>;
    final List<Widget> variationWidgets = [];

    variations.forEach((key, value) {
      if (value is Map) {
        // Если значение - объект с ценами {значение: цена}
        final options = value.entries.toList();
        variationWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                key,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map<Widget>((entry) {
                  final optionStr = entry.key.toString();
                  final price = entry.value is num ? entry.value.toDouble() : 0.0;
                  final isSelected = _selectedVariations[key] == optionStr;
                  final priceText = price > 0 ? ' (+${price.toStringAsFixed(0)}₽)' : '';
                  return FilterChip(
                    label: Text('$optionStr$priceText'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedVariations[key] = optionStr;
                        } else {
                          _selectedVariations.remove(key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      } else if (value is List) {
        // Если значение - список (старый формат), показываем чипсы для выбора
        variationWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                key,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: value.map<Widget>((option) {
                  final optionStr = option.toString();
                  final isSelected = _selectedVariations[key] == optionStr;
                  return FilterChip(
                    label: Text(optionStr),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedVariations[key] = optionStr;
                        } else {
                          _selectedVariations.remove(key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      } else {
        // Если значение - строка или другой тип, показываем как текст
        variationWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Text(
                  '$key: ',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: variationWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.i('ProductDetailScreen build');

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Товар'),
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProductError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Товар'),
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Ошибка', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text('Не удалось загрузить товар. Попробуйте еще раз.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProductBloc>().add(
                        LoadProduct(widget.productId),
                      );
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProductLoaded) {
          final product = state.product;

          return Scaffold(
            appBar: AppBar(
              title: Text(product.title),
              leading: Navigator.canPop(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image — контейнер по высоте, соотношение сторон сохраняет картинка
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: Container(
                      height: 320,
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? Image.network(
                              ApiConstants.imageProxyFull(product.imageUrl!, AppConfig.baseUrl),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              cacheWidth: 800,
                              cacheHeight: 800,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 64,
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 64,
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      color: Theme.of(context).colorScheme.outline,
                      height: 2,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product title
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                // Price with variations
                                Builder(
                                  builder: (context) {
                                    // Базовая цена с учетом скидки
                                    double basePrice = product.currentPrice;
                                    double originalPrice = product.price;
                                    
                                    // Добавляем цены выбранных вариаций
                                    if (product.variations != null && _selectedVariations.isNotEmpty) {
                                      final variations = product.variations as Map<String, dynamic>;
                                      for (final entry in _selectedVariations.entries) {
                                        final varKey = entry.key;
                                        final varValue = entry.value;
                                        if (variations.containsKey(varKey)) {
                                          final varData = variations[varKey];
                                          if (varData is Map && varData.containsKey(varValue)) {
                                            final price = varData[varValue];
                                            if (price is num) {
                                              basePrice += price.toDouble();
                                              originalPrice += price.toDouble();
                                            }
                                          }
                                        }
                                      }
                                    }
                                    
                                    // Если есть активная скидка, показываем новую цену и старую справа
                                    if (product.hasActiveDiscount && basePrice < originalPrice) {
                                      final colorScheme = Theme.of(context).colorScheme;
                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${basePrice.toStringAsFixed(0)} ₽',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.tertiary,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: colorScheme.tertiary.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              product.discountPercentage != null
                                                  ? '-${product.discountPercentage!.toStringAsFixed(0)}%'
                                                  : 'Скидка',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: colorScheme.tertiary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Старая цена справа (зачеркнутая) в красивом контейнере
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: colorScheme.outline.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              '${originalPrice.toStringAsFixed(0)} ₽',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    decoration: TextDecoration.lineThrough,
                                                    decorationThickness: 2,
                                                    color: colorScheme.onSurface.withOpacity(0.6),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    
                                    // Обычная цена без скидки
                                    return Text(
                                      '${basePrice.toStringAsFixed(0)} ₽',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            BlocBuilder<ProductBloc, ProductState>(
                              builder: (context, productState) {
                                if (productState is! ProductLoaded) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: AnimatedCartButton(
                                    key: ValueKey('${product.id}_${_selectedVariations.toString()}'),
                                    product: product,
                                    selectedVariations: _selectedVariations.isNotEmpty 
                                        ? Map<String, String>.from(_selectedVariations)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Variations
                        _buildVariationsSelector(product),
                        const SizedBox(height: 16),
                        // Description
                        if (product.description != null) ...[
                          Text(
                            'Описание',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.description!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                if (cartState is! CartLoaded || cartState.itemCount == 0) {
                  return const SizedBox.shrink();
                }

                final cartItemCount = cartState.itemCount;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FloatingActionButton(
                      key: const ValueKey('cart_fab_product_detail'),
                      onPressed: AppRouter.toCart,
                      child: const Icon(Icons.shopping_cart),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Center(
                            child: Text(
                              cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Товар')),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
