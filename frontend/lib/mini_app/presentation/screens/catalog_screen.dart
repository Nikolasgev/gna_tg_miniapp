import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/core/services/business_service.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/mini_app/presentation/bloc/cart/cart_bloc.dart';
import 'package:tg_store/mini_app/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:tg_store/mini_app/presentation/navigation/app_router.dart';
import 'package:tg_store/mini_app/presentation/widgets/product_card.dart';
import 'package:tg_store/mini_app/presentation/widgets/filters_dialog.dart';
import 'package:tg_store/mini_app/presentation/screens/orders_history_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/settings_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/support_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/loyalty_screen.dart';
import 'package:tg_store/l10n/app_localizations.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String? _businessSlug;
  double? _minPrice;
  double? _maxPrice;
  String? _priceSort; // 'asc', 'desc', null
  String? _businessName;
  String? _businessLogo;
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    
    // Загружаем business slug и затем продукты
    _loadBusinessSlugAndProducts();
  }

  Future<void> _loadBusinessSlugAndProducts() async {
    // Получаем business slug
    _businessSlug = await BusinessService.getBusinessSlug() ?? 'default-business';
    
    // Загружаем настройки бизнеса
    await _loadBusinessSettings();
    
    // Load products after first frame (categories will be loaded automatically)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Загружаем только продукты, категории загрузятся автоматически в BLoC
        // Применяем текущие фильтры по цене, если они установлены
        context.read<CatalogBloc>().add(LoadProducts(_businessSlug!, minPrice: _minPrice, maxPrice: _maxPrice));
      } catch (e) {
        // Логируем только критичные ошибки
      }
    });
  }

  Future<void> _loadBusinessSettings() async {
    if (_businessSlug == null) return;
    
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.businessSettings(_businessSlug!),
      );
      
      if (response.statusCode == 200 && mounted) {
        final data = response.data;
        final logoUrl = data['logo'] as String?;
        setState(() {
          _businessName = data['name'] as String?;
          _businessLogo = logoUrl;
        });
      }
    } catch (e) {
      // Не критично, продолжаем работу с дефолтным названием
    }
  }

  String _getProxiedImageUrl(String originalUrl) {
    // Используем прокси для обхода CORS
    return '${AppConfig.baseUrl}${ApiConstants.imageProxy(originalUrl)}';
  }

  void _onCategorySelected(String? categoryId) {
    if (_businessSlug != null) {
      context.read<CatalogBloc>().add(
            FilterByCategory(
              _businessSlug!,
              categoryId,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
            ),
          );
    }
  }

  Future<void> _showFiltersDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FiltersDialog(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        priceSort: _priceSort,
      ),
    );

    if (result != null) {
      final newMinPrice = result['minPrice'] as double?;
      final newMaxPrice = result['maxPrice'] as double?;
      final newPriceSort = result['priceSort'] as String?;
      
      
      setState(() {
        _minPrice = newMinPrice;
        _maxPrice = newMaxPrice;
        _priceSort = newPriceSort;
      });

      // Применяем фильтры и сортировку
      if (_businessSlug != null) {
        
        // Сначала загружаем продукты с фильтрами по цене
        context.read<CatalogBloc>().add(
          LoadProducts(
            _businessSlug!,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
          ),
        );

        // Если выбрана сортировка, применяем её после небольшой задержки
        // чтобы LoadProducts успел выполниться
        if (_priceSort != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _businessSlug != null) {
              final sortType = _priceSort == 'asc' ? 'price_asc' : 'price_desc';
              logger.d('🔍 CatalogScreen: Dispatching SortProducts: $sortType');
              context.read<CatalogBloc>().add(SortProducts(_businessSlug!, sortType));
            }
          });
        }
      }
    }
  }

  Widget _buildStyledMenuButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.more_vert,
          color: colorScheme.onSurface,
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      elevation: 8,
      color: colorScheme.surface,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      onSelected: (value) {
        switch (value) {
          case 'orders':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrdersHistoryScreen(),
              ),
            );
            break;
          case 'settings':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
            break;
          case 'support':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupportScreen(),
              ),
            );
            break;
          case 'loyalty':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoyaltyScreen(),
              ),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return [
          _buildMenuItem(
            context,
            icon: Icons.receipt_long_rounded,
            iconColor: colorScheme.primary,
            title: l10n.ordersHistory,
            subtitle: l10n.ordersHistorySubtitle,
            value: 'orders',
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings_rounded,
            iconColor: colorScheme.tertiary,
            title: l10n.settings,
            subtitle: l10n.settingsSubtitle,
            value: 'settings',
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline_rounded,
            iconColor: colorScheme.onSecondaryContainer,
            title: l10n.support,
            subtitle: l10n.supportSubtitle,
            value: 'support',
          ),
        ];
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.only(left: 16, right: 20, top: 12, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.i('CatalogScreen build called');
    logger.i('Business logo: $_businessLogo');
    logger.i('Business name: $_businessName');
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Фон из темы
      appBar: AppBar(
        leading: _businessLogo != null && _businessLogo!.isNotEmpty
            ? Builder(
                builder: (context) {
                  logger.i('Building logo widget with URL: $_businessLogo');
                  // Используем прокси для обхода CORS
                  final logoUrl = _getProxiedImageUrl(_businessLogo!);
                  logger.i('Proxied logo URL: $logoUrl');
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        logoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        // Оптимизация: ограничение размера кеша
                        cacheWidth: 200,
                        cacheHeight: 200,
                        errorBuilder: (context, error, stackTrace) {
                          logger.e('Error loading business logo', 
                            error: error,
                            stackTrace: stackTrace,
                          );
                          logger.e('Logo URL: $_businessLogo');
                          logger.e('Proxied URL: $logoUrl');
                          // Показываем placeholder вместо скрытия
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.business, size: 24, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            logger.i('Business logo loaded successfully');
                            return child;
                          }
                          logger.i('Loading logo: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                          return const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              )
            : null,
        title: Text(_businessName ?? AppLocalizations.of(context)!.catalogProducts),
        actions: [
          _buildStyledMenuButton(context),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          // Categories (всегда отображаются)
          const SizedBox(height: 4),
          BlocBuilder<CatalogBloc, CatalogState>(
            builder: (context, state) {
              logger.d('Categories BlocBuilder state: ${state.runtimeType}');
              
              // Получаем категории через геттер
              final categories = state.categories;
              
              // Получаем selectedCategoryId из состояний, которые его содержат
              String? selectedCategoryId;
              if (state is CatalogCategoriesLoaded) {
                selectedCategoryId = state.selectedCategoryId;
              } else if (state is CatalogLoaded) {
                selectedCategoryId = state.selectedCategoryId;
              } else if (state is CatalogProductsLoaded) {
                selectedCategoryId = state.selectedCategoryId;
              }
              
              // Категории загружаются автоматически вместе с продуктами в _onLoadProducts
              // Не нужно вызывать LoadCategories отдельно
              
              if (categories != null && categories.isNotEmpty) {
                logger.i('Categories loaded: ${categories.length} items');
                final categoriesList = categories; // Safe after null check
                return SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      // Кнопка фильтра слева от чипсов
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFiltersDialog,
                          tooltip: AppLocalizations.of(context)!.filters,
                          iconSize: 24,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      // Чипсы категорий
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          children: [
                            // "All" category
                            _CategoryChip(
                              label: AppLocalizations.of(context)!.all,
                              isSelected: selectedCategoryId == null,
                              onTap: () => _onCategorySelected(null),
                            ),
                            // Category chips with spacing
                            ...categoriesList.expand((category) {
                              return [
                                const SizedBox(width: 8),
                                _CategoryChip(
                                  label: category.name,
                                  isSelected: selectedCategoryId == category.id,
                                  onTap: () => _onCategorySelected(category.id),
                                ),
                              ];
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              logger.w('Categories not available or empty. State: ${state.runtimeType}');
              // Показываем индикатор загрузки, если категории еще не загружены
              if (state is CatalogInitial || (state is CatalogLoading && state.categories == null)) {
                return const SizedBox(
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 8),
          // Products list
          Expanded(
            child: BlocBuilder<CatalogBloc, CatalogState>(
              buildWhen: (previous, current) {
                // Всегда перестраиваем, чтобы видеть изменения
                logger.d('🔄 BlocBuilder buildWhen: ${previous.runtimeType} -> ${current.runtimeType}');
                logger.d('BlocBuilder buildWhen: ${previous.runtimeType} -> ${current.runtimeType}');
                return true;
              },
              builder: (context, state) {
                logger.d('🏗️ BlocBuilder building with state: ${state.runtimeType}');
                logger.d('Products BlocBuilder state: ${state.runtimeType}');
                
                // Показываем индикатор загрузки только при первичной загрузке
                if (state is CatalogInitial) {
                  logger.d('⏳ CATALOG: Initial state, showing loading...');
                  logger.i('Initial state, showing loading...');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Состояние: CatalogInitial', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                }
                
                // Если идет загрузка и нет продуктов, показываем индикатор
                if (state is CatalogLoading && state.products == null) {
                  logger.d('⏳ CATALOG: Loading without products...');
                  logger.i('Loading without products...');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Состояние: CatalogLoading (без продуктов)', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                }

                if (state is CatalogError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.loadingError,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Не удалось загрузить каталог. Проверьте подключение к интернету.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              if (_businessSlug != null) {
                                context.read<CatalogBloc>().add(LoadProducts(_businessSlug!, minPrice: _minPrice, maxPrice: _maxPrice));
                              }
                            },
                            child: Text(AppLocalizations.of(context)!.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Явно проверяем состояние CatalogLoaded
                if (state is CatalogLoaded) {
                  final products = state.products;
                  logger.i('✅ CatalogLoaded: ${products.length} products, ${state.categories.length} categories');
                  logger.d('✅✅✅ CATALOG SCREEN: CatalogLoaded with ${products.length} products');
                  
                  if (products.isNotEmpty) {
                    logger.d('✅✅✅ CATALOG SCREEN: Building responsive layout with ${products.length} products');
                    return RefreshIndicator(
                      onRefresh: () async {
                        if (_businessSlug != null) {
                          context.read<CatalogBloc>().add(LoadProducts(_businessSlug!, minPrice: _minPrice, maxPrice: _maxPrice));
                        }
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Определяем количество колонок в зависимости от ширины экрана
                          final isVeryWideScreen = constraints.maxWidth > 1200; // Очень широкий экран - 3 колонки
                          final isWideScreen = constraints.maxWidth > 600; // Широкий экран - 2 колонки
                          
                          if (isVeryWideScreen) {
                            // GridView для очень широких экранов (3 колонки)
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 420, // Фиксированная высота карточки
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return SizedBox(
                                  height: 420,
                                  child: ProductCard(
                                    product: product,
                                    margin: EdgeInsets.zero, // Убираем отступы для GridView
                                  ),
                                );
                              },
                            );
                          } else if (isWideScreen) {
                            // GridView для широких экранов (2 колонки)
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 420, // Фиксированная высота карточки
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return SizedBox(
                                  height: 420,
                                  child: ProductCard(
                                    product: product,
                                    margin: EdgeInsets.zero, // Убираем отступы для GridView
                                  ),
                                );
                              },
                            );
                          } else {
                            // ListView для узких экранов (1 колонка)
                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 56),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return ProductCard(
                                  product: product,
                                );
                              },
                            );
                          }
                        },
                      ),
                    );
                  }
                }
                
                // Get products from state (fallback)
                final products = state.products;
                logger.d('State: ${state.runtimeType}, Products: ${products?.length ?? 'null'}');

                if (products != null && products.isNotEmpty) {
                  logger.i('Products loaded: ${products.length} items');
                  
                  final productsList = products; // Non-nullable reference
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      if (_businessSlug != null) {
                        context.read<CatalogBloc>().add(LoadProducts(_businessSlug!, minPrice: _minPrice, maxPrice: _maxPrice));
                      }
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Определяем количество колонок в зависимости от ширины экрана
                        final isVeryWideScreen = constraints.maxWidth > 1200; // Очень широкий экран - 3 колонки
                        final isWideScreen = constraints.maxWidth > 600; // Широкий экран - 2 колонки
                        
                        if (isVeryWideScreen) {
                          // GridView для очень широких экранов (3 колонки)
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 420, // Фиксированная высота карточки
                            ),
                            itemCount: productsList.length,
                            itemBuilder: (context, index) {
                              final product = productsList[index];
                              return SizedBox(
                                height: 420,
                                child: ProductCard(
                                  product: product,
                                  margin: EdgeInsets.zero, // Убираем отступы для GridView
                                ),
                              );
                            },
                          );
                        } else if (isWideScreen) {
                          // GridView для широких экранов (2 колонки)
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 420, // Фиксированная высота карточки
                            ),
                            itemCount: productsList.length,
                            itemBuilder: (context, index) {
                              final product = productsList[index];
                              return SizedBox(
                                height: 420,
                                child: ProductCard(
                                  product: product,
                                  margin: EdgeInsets.zero, // Убираем отступы для GridView
                                ),
                              );
                            },
                          );
                        } else {
                          // ListView для узких экранов (1 колонка)
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: productsList.length,
                            itemBuilder: (context, index) {
                              final product = productsList[index];
                              return ProductCard(
                                product: product,
                              );
                            },
                          );
                        }
                      },
                    ),
                  );
                }

                if (products != null && products.isEmpty) {
                  logger.w('Products list is empty');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.productsNotFound,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.tryChangeSearchParams,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                // Если продукты еще не загружены, показываем индикатор загрузки
                if (products == null) {
                  logger.d('❌ CATALOG: Products are null! State: ${state.runtimeType}');
                  logger.i('Products are null, showing loading...');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Продукты: null', style: Theme.of(context).textTheme.bodySmall),
                        Text('Состояние: ${state.runtimeType}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                }

                // Если дошли сюда, но продуктов нет, показываем индикатор
                logger.d('❌ CATALOG: Fallback - showing loading. State: ${state.runtimeType}, Products: ${products.length}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Неизвестное состояние', style: Theme.of(context).textTheme.bodySmall),
                      Text('Тип: ${state.runtimeType}', style: Theme.of(context).textTheme.bodySmall),
                      Text('Продукты: ${products.length}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final cartItemCount = cartState is CartLoaded ? cartState.itemCount : 0;
          
          // Показываем FAB только если в корзине есть товары
          if (cartItemCount == 0) {
            return const SizedBox.shrink();
          }
          
          return Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                key: const ValueKey('cart_fab'),
                onPressed: () {
                  AppRouter.toCart();
                },
                child: const Icon(Icons.shopping_cart),
              ),
              // Счетчик в правом верхнем углу FAB
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
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
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
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipTheme = theme.chipTheme;
    
    return SizedBox(
      height: 32, // Фиксированная высота для всех чипсов категорий
      child: FilterChip(
        label: Text(
          label,
          style: isSelected
              ? TextStyle(
                  color: theme.colorScheme.onPrimary, // Белый цвет для выбранного чипса
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )
              : chipTheme.labelStyle, // Используем цвет из темы для обычного состояния
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: theme.colorScheme.primary, // Используем primary для фона выбранного чипса
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

