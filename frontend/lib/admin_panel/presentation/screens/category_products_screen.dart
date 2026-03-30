import 'dart:async';
import 'package:tg_store/core/utils/logger.dart' show logger;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/admin_panel/presentation/screens/products_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String businessSlug;
  final Map<String, dynamic> category;

  const CategoryProductsScreen({
    super.key,
    required this.businessSlug,
    required this.category,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _error;
  String? _searchQuery;
  bool? _filterActive; // null = все, true = только активные, false = только неактивные
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final queryParams = <String, dynamic>{
        'category': widget.category['id'],
        'include_inactive': true, // Показываем все товары, включая неактивные
        '_t': DateTime.now().millisecondsSinceEpoch, // Добавляем timestamp для обхода кэша
      };

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        queryParams['q'] = _searchQuery;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.adminProducts(widget.businessSlug),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        var products = List<dynamic>.from(response.data);
        
        // Фильтруем по статусу на фронте (если нужно)
        if (_filterActive != null) {
          products = products.where((p) => p['is_active'] == _filterActive).toList();
        }
        
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.isEmpty ? null : value;
    });
    _loadProducts();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = null;
    });
    _loadProducts();
  }

  void _onStatusFilterChanged(bool? status) {
    setState(() {
      _filterActive = status;
    });
    _loadProducts();
  }

  Future<void> _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProductScreen(
          businessSlug: widget.businessSlug,
          defaultCategoryId: widget.category['id'],
        ),
      ),
    );

    if (result == true) {
      await _loadProducts();
    }
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProductScreen(
          businessSlug: widget.businessSlug,
          product: product,
        ),
      ),
    );

    if (result == true) {
      await _loadProducts();
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: Text('Вы уверены, что хотите полностью удалить "${product['title']}"? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        logger.d('🗑️ Deleting product: ${product['id']}');
        final response = await _apiClient.dio.delete(
          ApiConstants.adminProduct(product['id']),
          options: Options(
            validateStatus: (status) {
              return status != null && (status == 204 || status == 200 || status < 500);
            },
          ),
        );
        
        logger.d('✅ Delete response status: ${response.statusCode}');
        
        if (response.statusCode == 204 || response.statusCode == 200) {
          if (mounted) {
            logger.d('✅ Product deleted successfully, reloading list...');
            await _loadProducts();
            logger.d('✅ List reloaded after delete');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Товар успешно удален'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        } else {
          throw Exception('Неожиданный статус ответа: ${response.statusCode}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Не удалось удалить товар. Попробуйте еще раз.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _removeProductFromCategory(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар из категории?'),
        content: Text('Вы уверены, что хотите удалить "${product['title']}" из категории "${widget.category['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Получаем текущие категории товара (как UUID строки)
        final List<String> currentCategoryIds = (product['category_ids'] as List<dynamic>?)
            ?.map((id) => id.toString())
            .toList() ?? [];

        // Удаляем текущую категорию из списка
        final categoryIdToRemove = widget.category['id'].toString();
        currentCategoryIds.removeWhere((id) => id == categoryIdToRemove);

        // Обновляем товар (отправляем UUID как строки, бэкенд их преобразует)
        final response = await _apiClient.dio.patch(
          ApiConstants.adminProduct(product['id']),
          data: {
            'category_ids': currentCategoryIds,
          },
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Товар удален из категории'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            await _loadProducts();
          }
        } else {
          throw Exception('Неожиданный статус ответа: ${response.statusCode}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Не удалось удалить товар. Попробуйте еще раз.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Товары: ${widget.category['name']}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Поиск
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск по названию или SKU',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    // Debounce поиск
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                      if (mounted && _searchController.text == value) {
                        _onSearchChanged(value);
                      }
                    });
                  },
                ),
              ),
              // Фильтры - по активности
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('Все'),
                        selected: _filterActive == null,
                        onSelected: (_) => _onStatusFilterChanged(null),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('Активные'),
                        selected: _filterActive == true,
                        onSelected: (_) => _onStatusFilterChanged(true),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('Неактивные'),
                        selected: _filterActive == false,
                        onSelected: (_) => _onStatusFilterChanged(false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ошибка',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProducts,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Нет товаров в категории',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите + чтобы добавить товар',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(product['title'] ?? 'Без названия'),
                              subtitle: Text(
                                '${product['price']} ${product['currency'] ?? 'RUB'}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    product['is_active'] == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: product['is_active'] == true
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editProduct(product),
                                    tooltip: 'Редактировать',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline, 
                                      color: Theme.of(context).colorScheme.tertiary,
                                    ),
                                    onPressed: () => _removeProductFromCategory(product),
                                    tooltip: 'Удалить из категории',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete, 
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () => _deleteProduct(product),
                                    tooltip: 'Удалить товар',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}

