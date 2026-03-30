import 'dart:async';
import 'package:tg_store/core/utils/logger.dart' show logger;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:intl/intl.dart';

// Условные импорты для веба и нативных платформ
import 'dart:html' if (dart.library.io) 'dart:io' as platform;

class ProductsScreen extends StatefulWidget {
  final String businessSlug;

  const ProductsScreen({
    super.key,
    required this.businessSlug,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _error;
  String? _searchQuery;
  String? _selectedCategoryId;
  bool? _filterActive; // null = все, true = только активные, false = только неактивные
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  List<dynamic> _categories = [];

  Future<void> _loadCategories() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.adminCategories(widget.businessSlug),
      );
      if (response.statusCode == 200) {
        setState(() {
          _categories = List<dynamic>.from(response.data);
        });
      }
    } catch (e) {
      logger.d('❌ Error loading categories: $e');
    }
  }

  Future<void> _loadProducts() async {
    logger.d('🔄 _loadProducts called for business: ${widget.businessSlug}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.d('📡 Requesting products from API...');
      final queryParams = <String, dynamic>{
        '_t': DateTime.now().millisecondsSinceEpoch, // Добавляем timestamp для обхода кэша
        'include_inactive': true, // В админке показываем все товары, включая неактивные
      };

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        queryParams['q'] = _searchQuery;
      }

      if (_selectedCategoryId != null) {
        queryParams['category'] = _selectedCategoryId;
      }

      // Фильтр по статусу: если null - все, если true - только активные, если false - только неактивные
      if (_filterActive != null) {
        // Для фильтрации по статусу используем include_inactive
        // Если _filterActive == true, показываем только активные (include_inactive=false)
        // Если _filterActive == false, показываем только неактивные (нужно будет фильтровать на фронте или добавить параметр)
        // Пока фильтруем на фронте после загрузки
      }

      final response = await _apiClient.dio.get(
        ApiConstants.adminProducts(widget.businessSlug),
        queryParameters: queryParams,
      );

      logger.d('✅ Response status: ${response.statusCode}');
      logger.d('📦 Products count: ${response.data?.length ?? 0}');

        if (response.statusCode == 200) {
        var products = List<dynamic>.from(response.data);
        
        // Фильтруем по статусу на фронте (если нужно)
        if (_filterActive != null) {
          products = products.where((p) => p['is_active'] == _filterActive).toList();
        }
        
        logger.d('✅ Setting ${products.length} products to state');
        logger.d('   Product IDs: ${products.map((p) => p['id']).toList()}');
        setState(() {
          _products = products;
          _isLoading = false;
        });
        logger.d('✅ State updated, products count: ${_products.length}');
        logger.d('   Current product IDs in state: ${_products.map((p) => p['id']).toList()}');
      } else {
        logger.d('❌ Unexpected status code: ${response.statusCode}');
        setState(() {
          _error = 'Неожиданный статус ответа: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.d('❌ Error loading products: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProductScreen(
          businessSlug: widget.businessSlug,
        ),
      ),
    );

    logger.d('📝 CreateProduct result: $result');
    if (result == true) {
      logger.d('✅ Product created, reloading list...');
      // Обновляем список товаров после создания
      await _loadProducts();
      logger.d('✅ List reloaded after create');
    } else {
      logger.d('⚠️ CreateProduct returned false or null');
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

    logger.d('✏️ EditProduct result: $result');
    if (result == true) {
      logger.d('✅ Product updated, reloading list...');
      // Обновляем список товаров после редактирования
      await _loadProducts();
      logger.d('✅ List reloaded after edit');
    } else {
      logger.d('⚠️ EditProduct returned false or null');
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    logger.d('🗑️ _deleteProduct called for product: ${product['id']} - ${product['title']}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: Text('Вы уверены, что хотите удалить "${product['title']}"?'),
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
              // Принимаем 200 как успешный ответ (теперь возвращаем JSON)
              return status != null && (status == 200 || status < 500);
            },
          ),
        );
        
        logger.d('✅ Delete response status: ${response.statusCode}');
        logger.d('✅ Delete response data: ${response.data}');
        
        if (response.statusCode == 200) {
          if (mounted) {
            logger.d('✅ Product deleted/deactivated successfully, reloading list...');
            // Сначала обновляем список товаров
            await _loadProducts();
            logger.d('✅ List reloaded after delete');
            
            // Проверяем, был ли товар деактивирован или удален
            final responseData = response.data;
            final isDeactivated = responseData != null && responseData['deactivated'] == true;
            final message = responseData != null && responseData['message'] != null
                ? responseData['message'] as String
                : (isDeactivated 
                    ? 'Статус изменен на неактивен, но невозможно удалить, так как используется в заказе'
                    : 'Товар успешно удален');
            
            // Показываем сообщение
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: isDeactivated 
                    ? Theme.of(context).colorScheme.tertiary 
                    : Theme.of(context).colorScheme.primary,
                duration: Duration(seconds: isDeactivated ? 5 : 3),
              ),
            );
          }
        } else {
          logger.d('❌ Unexpected status code: ${response.statusCode}');
          throw Exception('Неожиданный статус ответа: ${response.statusCode}');
        }
      } catch (e) {
        logger.d('❌ Error deleting product: $e');
        logger.d('   Error type: ${e.runtimeType}');
        if (e is DioException) {
          logger.d('   DioException type: ${e.type}');
          logger.d('   Response status: ${e.response?.statusCode}');
          logger.d('   Response data: ${e.response?.data}');
          logger.d('   Request path: ${e.requestOptions.path}');
        }
        if (mounted) {
          // Проверяем, является ли это ошибкой из-за использования в заказах
          String errorMessage = 'Ошибка удаления товара';
          if (e is DioException && e.response != null) {
            final responseData = e.response?.data;
            if (responseData != null && responseData['deactivated'] == true) {
              errorMessage = responseData['message'] as String? ?? 
                'Статус изменен на неактивен, но невозможно удалить, так как используется в заказе';
            } else if (responseData != null && responseData['message'] != null) {
              errorMessage = responseData['message'] as String;
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              duration: const Duration(seconds: 5),
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      logger.d('⚠️ Delete cancelled by user');
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

  void _onCategoryFilterChanged(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadProducts();
  }

  void _onStatusFilterChanged(bool? status) {
    setState(() {
      _filterActive = status;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Товары'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_categories.isNotEmpty ? 120 : 80),
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
              // Фильтры - первый ряд: по активности
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: FilterChip(
                          label: const Text('Все'),
                          selected: _filterActive == null,
                          onSelected: (_) => _onStatusFilterChanged(null),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: FilterChip(
                          label: const Text('Активные'),
                          selected: _filterActive == true,
                          onSelected: (_) => _onStatusFilterChanged(true),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: FilterChip(
                          label: const Text('Неактивные'),
                          selected: _filterActive == false,
                          onSelected: (_) => _onStatusFilterChanged(false),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Фильтры - второй ряд: по категориям
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: FilterChip(
                            label: const Text('Все категории'),
                            selected: _selectedCategoryId == null,
                            onSelected: (_) => _onCategoryFilterChanged(null),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      ..._categories.map((category) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: FilterChip(
                                label: Text(
                                  category['name'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                selected: _selectedCategoryId == category['id'],
                                onSelected: (_) => _onCategoryFilterChanged(category['id']),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          )),
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
                      Text('Ошибка: $_error'),
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
                          const Text('Нет товаров'),
                          const SizedBox(height: 8),
                          Text(
                            'Нажмите + чтобы добавить первый товар',
                            style: Theme.of(context).textTheme.bodySmall,
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: ${product['id']}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          fontSize: 11,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${product['price']} ${product['currency'] ?? 'RUB'}',
                                  ),
                                  if (product['stock_quantity'] != null) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          product['stock_quantity'] > 0 
                                              ? Icons.inventory_2 
                                              : Icons.inventory_2_outlined,
                                          size: 14,
                                          color: product['stock_quantity'] > 0 
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.error,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Склад: ${product['stock_quantity']} шт.',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: product['stock_quantity'] > 0 
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).colorScheme.error,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.all_inclusive,
                                          size: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Неограниченно',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                fontSize: 11,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              isThreeLine: true,
                              trailing: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      product['is_active'] == true
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: product['is_active'] == true
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _editProduct(product),
                                      tooltip: 'Редактировать',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete, 
                                        color: Theme.of(context).colorScheme.error, 
                                        size: 20,
                                      ),
                                      iconSize: 20,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _deleteProduct(product),
                                      tooltip: 'Удалить',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CreateProductScreen extends StatefulWidget {
  final String businessSlug;
  final Map<String, dynamic>? product;
  final String? defaultCategoryId;

  const CreateProductScreen({
    super.key,
    required this.businessSlug,
    this.product,
    this.defaultCategoryId,
  });

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  bool _isActive = true;
  String _currency = 'RUB';
  List<dynamic> _categories = [];
  List<String> _selectedCategoryIds = [];
  PlatformFile? _selectedImageFile; // Выбранный файл изображения
  String? _existingImageUrl; // URL существующего изображения (только для отображения)
  bool _imageWasRemoved = false; // Флаг, что пользователь явно удалил изображение
  
  // Вариации: список объектов {key: String, values: List<{value: String, price: double}>}
  List<Map<String, dynamic>> _variations = [];
  
  // Поля для скидок
  bool _hasDiscount = false;
  String _discountType = 'percentage'; // 'percentage' или 'fixed'
  final _discountPercentageController = TextEditingController();
  final _discountPriceController = TextEditingController();
  bool _hasDiscountPeriod = false;
  DateTime? _discountValidFrom;
  DateTime? _discountValidUntil;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _titleController.text = widget.product!['title'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _priceController.text = (widget.product!['price'] ?? 0).toString();
      _skuController.text = widget.product!['sku'] ?? '';
      if (widget.product!['stock_quantity'] != null) {
        _stockQuantityController.text = widget.product!['stock_quantity'].toString();
      }
      _existingImageUrl = widget.product!['image_url'] as String?;
      _imageWasRemoved = false; // Сбрасываем флаг при загрузке продукта
      // Загружаем вариации из JSON
      if (widget.product!['variations'] != null) {
        final variations = widget.product!['variations'] as Map<String, dynamic>;
        _variations = variations.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;
          
          // Если значение - объект (с ценами), преобразуем в список значений с ценами
          if (value is Map) {
            final valuesWithPrices = value.entries.map((e) => {
              'value': e.key.toString(),
              'price': e.value is num ? e.value.toDouble() : 0.0,
            }).toList();
            return {
              'key': key,
              'values': valuesWithPrices,
            };
          } else if (value is List) {
            // Если значение - список (старый формат), преобразуем в новый формат с нулевыми ценами
            final valuesWithPrices = value.map((v) => {
              'value': v.toString(),
              'price': 0.0,
            }).toList();
            return {
              'key': key,
              'values': valuesWithPrices,
            };
          } else {
            // Если значение - строка (старый формат)
            return {
              'key': key,
              'values': [
                {'value': value.toString(), 'price': 0.0}
              ],
            };
          }
        }).toList();
      }
      _isActive = widget.product!['is_active'] ?? true;
      _currency = widget.product!['currency'] ?? 'RUB';
      if (widget.product!['category_ids'] != null) {
        _selectedCategoryIds = List<String>.from(
          widget.product!['category_ids'].map((id) => id.toString()),
        );
      }
      // Загружаем данные скидок
      if (widget.product!['discount_percentage'] != null) {
        _hasDiscount = true;
        _discountType = 'percentage';
        _discountPercentageController.text = widget.product!['discount_percentage'].toString();
      } else if (widget.product!['discount_price'] != null) {
        _hasDiscount = true;
        _discountType = 'fixed';
        _discountPriceController.text = widget.product!['discount_price'].toString();
      }
      if (widget.product!['discount_valid_from'] != null) {
        _discountValidFrom = DateTime.tryParse(widget.product!['discount_valid_from']);
        _hasDiscountPeriod = true;
      }
      if (widget.product!['discount_valid_until'] != null) {
        _discountValidUntil = DateTime.tryParse(widget.product!['discount_valid_until']);
        _hasDiscountPeriod = true;
      }
    } else if (widget.defaultCategoryId != null) {
      // Если это создание нового товара и указана категория по умолчанию
      _selectedCategoryIds = [widget.defaultCategoryId!];
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.adminCategories(widget.businessSlug),
      );

      if (response.statusCode == 200) {
        setState(() {
          _categories = List<dynamic>.from(response.data);
        });
      }
    } catch (e) {
      // Игнорируем ошибки загрузки категорий
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Для веба используем HTML input элемент напрямую
      await _pickImageWeb();
    } else {
      // Для других платформ используем FilePicker
      await _pickImageNative();
    }
  }

  Future<void> _pickImageWeb() async {
    if (!kIsWeb) {
      return;
    }
    
    try {
      // Для веба используем dart:html напрямую через условный импорт
      // ignore: undefined_prefixed_name
      final input = platform.FileUploadInputElement()
        ..accept = 'image/*'
        ..multiple = false;
      
      input.click();
      
      // Ждем выбора файла
      await input.onChange.first;
      
      if (input.files != null && input.files!.isNotEmpty) {
        final htmlFile = input.files!.first;
        
        // Читаем файл как bytes
        // ignore: undefined_prefixed_name
        final reader = platform.FileReader();
        reader.readAsArrayBuffer(htmlFile);
        await reader.onLoadEnd.first;
        
        final bytes = reader.result as Uint8List?;
        
        if (bytes != null) {
          // Создаем PlatformFile из данных
          final platformFile = PlatformFile(
            name: htmlFile.name,
            size: htmlFile.size,
            bytes: bytes,
          );
          
          setState(() {
            _selectedImageFile = platformFile;
            // Очищаем поле URL при выборе файла
            _existingImageUrl = null;
            _imageWasRemoved = false; // Сбрасываем флаг удаления, т.к. выбран новый файл
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Файл выбран: ${htmlFile.name}'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Не удалось прочитать файл'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось выбрать файл. Попробуйте еще раз.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImageNative() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        if (file.path != null || file.bytes != null) {
          setState(() {
            _selectedImageFile = file;
            // Очищаем поле URL при выборе файла
            _existingImageUrl = null;
            _imageWasRemoved = false; // Сбрасываем флаг удаления, т.к. выбран новый файл
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Файл выбран: ${file.name}'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Не удалось получить данные файла'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось выбрать файл. Попробуйте еще раз.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null) {
      return null;
    }

    try {
      final fileName = _selectedImageFile!.name;
      Uint8List? fileBytes;
      
      // Для веб используем bytes напрямую, для других платформ - путь к файлу
      if (_selectedImageFile!.bytes != null) {
        // Flutter Web или файл уже загружен в память - используем bytes
        fileBytes = _selectedImageFile!.bytes;
      } else if (_selectedImageFile!.path != null && !kIsWeb) {
        // Другие платформы (не веб) - читаем файл с диска
        // Для веба этот путь не используется, так как bytes уже доступны
        throw Exception('Для веб-платформы файл должен содержать bytes. Используйте _pickImageWeb().');
      } else {
        throw Exception('Не удалось получить данные файла. Файл не содержит ни bytes, ни path.');
      }
      
      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception('Файл пуст или не удалось получить данные');
      }
      
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post(
        ApiConstants.uploadImage,
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final imageUrl = data['url'] as String;
        
        // Возвращаем относительный URL (начинается с /api/v1/images/uploads/)
        // Это позволит использовать изображение на разных доменах
        if (imageUrl.startsWith('/')) {
          return imageUrl;
        }
        // Если API вернул полный URL, извлекаем относительный путь
        if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
          final uri = Uri.parse(imageUrl);
          return uri.path;
        }
        // Если это просто имя файла, добавляем путь
        return '/api/v1/images/uploads/$imageUrl';
      } else {
        throw Exception('Ошибка загрузки: статус ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось загрузить изображение. Попробуйте еще раз.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Проверка дат скидки
    if (_hasDiscount && _hasDiscountPeriod) {
      if (_discountValidFrom != null && _discountValidUntil != null) {
        if (_discountValidUntil!.isBefore(_discountValidFrom!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Дата окончания должна быть позже даты начала'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем изображение, если выбран новый файл
      String? imageUrl;
      if (_selectedImageFile != null) {
        // Если выбран новый файл, загружаем его
        final uploadedUrl = await _uploadImage();
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          // Если загрузка не удалась, не продолжаем
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } else if (_imageWasRemoved) {
        // Если пользователь явно удалил изображение, отправляем null
        imageUrl = null;
      } else if (widget.product != null && _existingImageUrl != null) {
        // Если это обновление и изображение не менялось, отправляем старое значение
        imageUrl = _existingImageUrl;
      }
      // Если это создание нового продукта и изображение не выбрано, imageUrl останется null

      // Преобразуем вариации в JSON формат {ключ: {значение: цена}}
      Map<String, dynamic>? variations;
      if (_variations.isNotEmpty) {
        variations = {};
        for (final variation in _variations) {
          final key = (variation['key'] as String? ?? '').trim();
          final values = variation['values'] as List<dynamic>? ?? [];
          
          if (key.isNotEmpty && values.isNotEmpty) {
            final valueMap = <String, double>{};
            for (final val in values) {
              final valueStr = (val['value'] as String? ?? '').trim();
              final price = (val['price'] as num? ?? 0.0).toDouble();
              if (valueStr.isNotEmpty) {
                valueMap[valueStr] = price;
              }
            }
            if (valueMap.isNotEmpty) {
              variations[key] = valueMap;
            }
          }
        }
        if (variations.isEmpty) {
          variations = null;
        }
      }

      final data = <String, dynamic>{
        'title': _titleController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'price': double.parse(_priceController.text),
        'currency': _currency,
        'sku': _skuController.text.isEmpty ? null : _skuController.text,
        'stock_quantity': _stockQuantityController.text.isEmpty 
            ? null 
            : int.tryParse(_stockQuantityController.text),
        'variations': variations,
        'is_active': _isActive,
        'category_ids': _selectedCategoryIds,
      };
      
      // Добавляем поля скидок
      if (_hasDiscount) {
        if (_discountType == 'percentage' && _discountPercentageController.text.isNotEmpty) {
          data['discount_percentage'] = double.tryParse(_discountPercentageController.text);
          data['discount_price'] = null;
        } else if (_discountType == 'fixed' && _discountPriceController.text.isNotEmpty) {
          data['discount_price'] = double.tryParse(_discountPriceController.text);
          data['discount_percentage'] = null;
        }
        if (_hasDiscountPeriod) {
          data['discount_valid_from'] = _discountValidFrom?.toIso8601String();
          data['discount_valid_until'] = _discountValidUntil?.toIso8601String();
        } else {
          data['discount_valid_from'] = null;
          data['discount_valid_until'] = null;
        }
      } else {
        // Если скидка отключена, удаляем все поля скидок
        data['discount_percentage'] = null;
        data['discount_price'] = null;
        data['discount_valid_from'] = null;
        data['discount_valid_until'] = null;
      }
      
      // Добавляем image_url только если он был изменен
      // Для обновления: если imageUrl != null (новый файл или удаление), отправляем
      // Для создания: всегда отправляем imageUrl (может быть null)
      if (widget.product != null) {
        // При обновлении отправляем image_url только если он изменился
        if (_selectedImageFile != null || _imageWasRemoved || imageUrl != null) {
          data['image_url'] = imageUrl;
        }
        // Если image_url не менялся, не отправляем поле - бэкенд сохранит старое значение
        // stock_quantity уже добавлен в data выше и всегда отправляется при обновлении
      } else {
        // При создании всегда отправляем image_url
        data['image_url'] = imageUrl;
        // stock_quantity уже добавлен в data выше
      }

      if (widget.product != null) {
        // Обновление существующего продукта
        logger.d('🔄 Updating product: ${widget.product!['id']}');
        final response = await _apiClient.dio.put(
          ApiConstants.adminProduct(widget.product!['id']),
          data: data,
        );

        logger.d('📡 Update response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          if (mounted) {
            logger.d('✅ Product updated, popping with true');
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось обновить товар. Попробуйте еще раз.')),
            );
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        // Создание нового продукта
        logger.d('➕ Creating new product');
        final response = await _apiClient.dio.post(
          ApiConstants.adminProducts(widget.businessSlug),
          data: data,
        );

        logger.d('📡 Create response status: ${response.statusCode}');
        if (response.statusCode == 201) {
          if (mounted) {
            logger.d('✅ Product created, popping with true');
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Не удалось создать товар. Попробуйте еще раз.')),
            );
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Произошла ошибка. Попробуйте еще раз.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _stockQuantityController.dispose();
    _discountPercentageController.dispose();
    _discountPriceController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDiscountDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? (_discountValidFrom ?? DateTime.now())
        : (_discountValidUntil ?? DateTime.now().add(const Duration(days: 30)));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        final dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartDate) {
            _discountValidFrom = dateTime;
          } else {
            _discountValidUntil = dateTime;
          }
        });
      }
    }
  }
  
  void _addVariation() {
    setState(() {
      _variations.add({
        'key': '',
        'values': [],
      });
    });
  }
  
  void _removeVariation(int index) {
    setState(() {
      _variations.removeAt(index);
    });
  }
  
  void _updateVariationKey(int index, String key) {
    setState(() {
      _variations[index]['key'] = key;
    });
  }
  
  void _addVariationValue(int variationIndex) {
    setState(() {
      final values = _variations[variationIndex]['values'] as List<dynamic>;
      values.add({'value': '', 'price': 0.0});
    });
  }
  
  void _removeVariationValue(int variationIndex, int valueIndex) {
    setState(() {
      final values = _variations[variationIndex]['values'] as List<dynamic>;
      values.removeAt(valueIndex);
    });
  }
  
  void _updateVariationValueText(int variationIndex, int valueIndex, String value) {
    setState(() {
      final values = _variations[variationIndex]['values'] as List<dynamic>;
      values[valueIndex]['value'] = value;
    });
  }
  
  void _updateVariationValuePrice(int variationIndex, int valueIndex, String priceStr) {
    setState(() {
      final values = _variations[variationIndex]['values'] as List<dynamic>;
      final price = double.tryParse(priceStr) ?? 0.0;
      values[valueIndex]['price'] = price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Редактировать товар' : 'Новый товар'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Цена *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите цену';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Неверный формат';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _currency,
                  items: const [
                    DropdownMenuItem(value: 'RUB', child: Text('RUB')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _currency = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(
                labelText: 'SKU (артикул)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockQuantityController,
              decoration: const InputDecoration(
                labelText: 'Количество на складе',
                hintText: 'Оставьте пустым для неограниченного количества',
                border: OutlineInputBorder(),
                helperText: 'Введите число или оставьте пустым',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final numValue = int.tryParse(value);
                  if (numValue == null) {
                    return 'Введите корректное число';
                  }
                  if (numValue < 0) {
                    return 'Количество не может быть отрицательным';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Загрузка изображения
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Изображение товара',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Показываем существующее изображение, если есть
                if (_existingImageUrl != null && _selectedImageFile == null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            _existingImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Текущее изображение',
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                _existingImageUrl!,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _existingImageUrl = null;
                              _selectedImageFile = null;
                              _imageWasRemoved = true; // Помечаем, что изображение было удалено
                            });
                          },
                          tooltip: 'Удалить изображение',
                        ),
                      ],
                    ),
                  ),
                // Кнопка загрузки нового изображения
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_selectedImageFile != null ? 'Изменить файл' : 'Загрузить изображение'),
                  ),
                ),
              ],
            ),
            if (_selectedImageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.image, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedImageFile!.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedImageFile = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Вариации товара
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Вариации товара',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: TextButton.icon(
                    onPressed: _addVariation,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Добавить'),
                  ),
                ),
              ],
            ),
            if (_variations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Нет вариаций. Нажмите "Добавить" для создания.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ..._variations.asMap().entries.map((entry) {
              final variationIndex = entry.key;
              final variation = entry.value;
              final key = variation['key'] as String? ?? '';
              final values = variation['values'] as List<dynamic>? ?? [];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок категории вариации
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: key,
                              decoration: const InputDecoration(
                                labelText: 'Название категории',
                                hintText: 'например: размер',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) => _updateVariationKey(variationIndex, value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.delete, 
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _removeVariation(variationIndex),
                            tooltip: 'Удалить категорию',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Список значений с ценами
                      Text(
                        'Значения:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...values.asMap().entries.map((valueEntry) {
                        final valueIndex = valueEntry.key;
                        final valueData = valueEntry.value as Map<String, dynamic>;
                        final valueText = valueData['value'] as String? ?? '';
                        final price = valueData['price'] as num? ?? 0.0;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: valueText,
                                  decoration: const InputDecoration(
                                    labelText: 'Значение',
                                    hintText: 'например: S',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (value) => _updateVariationValueText(
                                    variationIndex,
                                    valueIndex,
                                    value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: price.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Цена',
                                    hintText: '0',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    suffixText: '₽',
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) => _updateVariationValuePrice(
                                    variationIndex,
                                    valueIndex,
                                    value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  Icons.delete, 
                                  color: Theme.of(context).colorScheme.error, 
                                  size: 20,
                                ),
                                onPressed: () => _removeVariationValue(variationIndex, valueIndex),
                                tooltip: 'Удалить значение',
                              ),
                            ],
                          ),
                        );
                      }),
                      // Кнопка добавления значения
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: TextButton.icon(
                          onPressed: () => _addVariationValue(variationIndex),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Добавить значение'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            // Секция скидок
            SwitchListTile(
              key: ValueKey('discount_switch_$_hasDiscount'),
              title: const Text(
                'Скидка на товар',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Включить скидку на этот товар'),
              value: _hasDiscount,
              onChanged: (value) {
                setState(() {
                  _hasDiscount = value;
                  if (!value) {
                    // При отключении скидки очищаем все связанные поля
                    _hasDiscountPeriod = false;
                    _discountValidFrom = null;
                    _discountValidUntil = null;
                    _discountPercentageController.clear();
                    _discountPriceController.clear();
                  }
                });
              },
              // Оптимизация для веб-платформы
              dense: false,
              visualDensity: VisualDensity.standard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            ),
            if (_hasDiscount) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('discount_type_dropdown_$_discountType'),
                initialValue: _discountType,
                decoration: const InputDecoration(
                  labelText: 'Тип скидки',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Процентная (%)'),
                  ),
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text('Фиксированная цена (₽)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      // Сначала очищаем противоположное поле
                      if (value == 'percentage') {
                        _discountPriceController.clear();
                      } else {
                        _discountPercentageController.clear();
                      }
                      // Затем меняем тип
                      _discountType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _discountType == 'percentage'
                    ? TextFormField(
                        key: const ValueKey('discount_percentage_field'),
                        controller: _discountPercentageController,
                        decoration: const InputDecoration(
                          labelText: 'Процент скидки (%)',
                          hintText: '10',
                          border: OutlineInputBorder(),
                          helperText: 'Введите число от 0 до 100',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (_hasDiscount && value != null && value.isNotEmpty) {
                            final numValue = double.tryParse(value);
                            if (numValue == null) {
                              return 'Введите корректное число';
                            }
                            if (numValue < 0 || numValue > 100) {
                              return 'Процент должен быть от 0 до 100';
                            }
                          }
                          return null;
                        },
                      )
                    : TextFormField(
                        key: const ValueKey('discount_price_field'),
                        controller: _discountPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Цена со скидкой (₽)',
                          hintText: '100',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (_hasDiscount && value != null && value.isNotEmpty) {
                            final numValue = double.tryParse(value);
                            if (numValue == null) {
                              return 'Введите корректное число';
                            }
                            if (numValue <= 0) {
                              return 'Цена должна быть больше 0';
                            }
                          }
                          return null;
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                key: ValueKey('discount_period_switch_$_hasDiscountPeriod'),
                title: const Text('Ограничить период действия'),
                value: _hasDiscountPeriod,
                onChanged: _hasDiscount
                    ? (value) {
                        setState(() {
                          _hasDiscountPeriod = value;
                          if (!value) {
                            _discountValidFrom = null;
                            _discountValidUntil = null;
                          }
                        });
                      }
                    : null, // Блокируем изменение, если скидка отключена
              ),
              if (_hasDiscountPeriod) ...[
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Дата начала'),
                  subtitle: Text(
                    _discountValidFrom != null
                        ? DateFormat('dd.MM.yyyy HH:mm').format(_discountValidFrom!)
                        : 'Не установлена',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDiscountDate(context, true),
                ),
                ListTile(
                  title: const Text('Дата окончания'),
                  subtitle: Text(
                    _discountValidUntil != null
                        ? DateFormat('dd.MM.yyyy HH:mm').format(_discountValidUntil!)
                        : 'Не установлена',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDiscountDate(context, false),
                ),
              ],
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Активен'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 8),
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Категории:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  final categoryId = category['id'] as String;
                  final isSelected = _selectedCategoryIds.contains(categoryId);
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: FilterChip(
                      label: Text(
                        category['name'] ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategoryIds.add(categoryId);
                          } else {
                            _selectedCategoryIds.remove(categoryId);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(widget.product != null ? 'Сохранить изменения' : 'Создать товар'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

