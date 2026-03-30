import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/presentation/bloc/cart/cart_bloc.dart';
import 'package:tg_store/mini_app/presentation/navigation/app_router.dart';
import 'package:tg_store/l10n/app_localizations.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    logger.i('CartScreen build');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cart),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          logger.d('CartScreen state: ${state.runtimeType}');
          
          if (state is CartInitial || (state is CartLoaded && state.items.isEmpty)) {
            logger.i('Cart is empty');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.cartEmpty,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.addItemsFromCatalog,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      AppRouter.toCatalog();
                    },
                    child: Text(AppLocalizations.of(context)!.goToCatalog),
                  ),
                ],
              ),
            );
          }

          if (state is CartLoaded) {
            logger.i('Cart has ${state.items.length} items, total: ${state.totalAmount.toStringAsFixed(0)} ₽');
            
            return Column(
              children: [
                // Cart items list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.product.imageUrl != null
                                ? Image.network(
                                    ApiConstants.imageProxyFull(item.product.imageUrl!, AppConfig.baseUrl),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.contain,
                                    // Оптимизация: ограничение размера кеша
                                    cacheWidth: 200,
                                    cacheHeight: 200,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        child: const Icon(Icons.image_not_supported),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                          ),
                          title: Text(item.product.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.selectedVariations != null && item.selectedVariations!.isNotEmpty) ...[
                                ...item.selectedVariations!.entries.map((entry) {
                                  // Получаем цену вариации из продукта
                                  String variationText = '${entry.key}: ${entry.value}';
                                  if (item.product.variations != null) {
                                    final variations = item.product.variations as Map<String, dynamic>;
                                    if (variations.containsKey(entry.key)) {
                                      final varData = variations[entry.key];
                                      if (varData is Map && varData.containsKey(entry.value)) {
                                        final price = varData[entry.value];
                                        if (price is num && price > 0) {
                                          variationText += ' (+${price.toStringAsFixed(0)}₽)';
                                        }
                                      }
                                    }
                                  }
                                  return Text(
                                    variationText,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                }),
                                const SizedBox(height: 4),
                              ],
                              Text('${item.product.currentPrice.toStringAsFixed(0)} ₽ × ${item.quantity}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${item.totalPrice.toStringAsFixed(0)} ₽',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  context.read<CartBloc>().add(
                                        RemoveFromCart(item.productId),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Total and checkout button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.total}:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${state.totalAmount.toStringAsFixed(0)} ₽',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            AppRouter.toCheckout();
                          },
                          style: FilledButton.styleFrom(
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(AppLocalizations.of(context)!.checkout),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

