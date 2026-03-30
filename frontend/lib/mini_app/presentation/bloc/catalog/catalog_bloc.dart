import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/domain/entities/category.dart';
import 'package:tg_store/mini_app/domain/entities/product.dart';
import 'package:tg_store/mini_app/domain/repositories/catalog_repository.dart';

part 'catalog_event.dart';
part 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogRepository catalogRepository;

  CatalogBloc({required this.catalogRepository}) : super(CatalogInitial()) {
    logger.i('CatalogBloc created');
    
    on<LoadCategories>(_onLoadCategories);
    on<LoadProducts>(_onLoadProducts);
    on<SearchProducts>(_onSearchProducts);
    on<FilterByCategory>(_onFilterByCategory);
    on<SortProducts>(_onSortProducts);
  }

  void _onLoadCategories(LoadCategories event, Emitter<CatalogState> emit) async {
    logger.i('LoadCategories event received for business: ${event.businessSlug}');
    
    // Preserve existing state
    final currentState = state;
    
    // Если состояние уже CatalogLoaded, не делаем ничего - категории уже есть
    if (currentState is CatalogLoaded) {
      logger.i('Categories already loaded in CatalogLoaded state, skipping');
      return;
    }
    
    List<Product>? existingProducts;
    String searchQuery = '';
    String? selectedCategoryId;
    
    if (currentState is CatalogProductsLoaded) {
      existingProducts = currentState.products;
      searchQuery = currentState.searchQuery;
      selectedCategoryId = currentState.selectedCategoryId;
    } else if (currentState is CatalogCategoriesLoaded) {
      existingProducts = currentState.products;
      searchQuery = currentState.searchQuery;
      selectedCategoryId = currentState.selectedCategoryId;
    }
    
    if (existingProducts == null) {
      emit(CatalogLoading(categories: null, products: null));
    } else {
      emit(CatalogLoading(categories: null, products: existingProducts));
    }
    logger.d('State emitted: CatalogLoading');
    
    // Загружаем категории из API
    final result = await catalogRepository.getCategories(event.businessSlug);
    
    result.fold(
      (failure) {
        logger.e('Failed to load categories: ${failure.message}');
        emit(CatalogError(failure.message));
      },
      (categories) {
        logger.i('Loaded ${categories.length} categories');
        
        if (existingProducts != null) {
          // Получаем фильтры по цене из текущего состояния
          double? minPrice;
          double? maxPrice;
          if (currentState is CatalogLoaded) {
            minPrice = currentState.minPrice;
            maxPrice = currentState.maxPrice;
          } else if (currentState is CatalogProductsLoaded) {
            minPrice = currentState.minPrice;
            maxPrice = currentState.maxPrice;
          }
          
          emit(CatalogLoaded(
            categories: categories,
            products: existingProducts,
            searchQuery: searchQuery,
            selectedCategoryId: selectedCategoryId,
            minPrice: minPrice,
            maxPrice: maxPrice,
          ));
          logger.i('State emitted: CatalogLoaded (both)');
        } else {
          emit(CatalogCategoriesLoaded(
            categories,
            searchQuery: searchQuery,
            selectedCategoryId: selectedCategoryId,
          ));
          logger.i('State emitted: CatalogCategoriesLoaded');
        }
      },
    );
  }

  void _onLoadProducts(LoadProducts event, Emitter<CatalogState> emit) async {
    logger.i('LoadProducts event received for business: ${event.businessSlug}');
    
    // Preserve existing state
    final currentState = state;
    List<Category>? existingCategories;
    String searchQuery = '';
    String? selectedCategoryId;
    
    if (currentState is CatalogCategoriesLoaded) {
      existingCategories = currentState.categories;
      searchQuery = currentState.searchQuery;
      selectedCategoryId = currentState.selectedCategoryId;
    } else if (currentState is CatalogLoaded) {
      existingCategories = currentState.categories;
      searchQuery = currentState.searchQuery;
      selectedCategoryId = currentState.selectedCategoryId;
    } else if (currentState is CatalogProductsLoaded) {
      existingCategories = currentState.categories;
      searchQuery = currentState.searchQuery;
      selectedCategoryId = currentState.selectedCategoryId;
    } else if (currentState is CatalogLoading && currentState.categories != null) {
      existingCategories = currentState.categories;
    }
    
    // Если категории еще не загружены, загружаем их
    if (existingCategories == null) {
      final categoriesResult = await catalogRepository.getCategories(event.businessSlug);
      categoriesResult.fold(
        (failure) {
          logger.e('Failed to load categories: ${failure.message}');
        },
        (categories) {
          existingCategories = categories;
          logger.i('Categories loaded: ${categories.length} items');
        },
      );
    }
    
    // Показываем состояние загрузки только если нет продуктов в текущем состоянии
    final hasProducts = currentState is CatalogLoaded || 
                       currentState is CatalogProductsLoaded ||
                       (currentState is CatalogLoading && currentState.products != null);
    
    if (!hasProducts && currentState is! CatalogInitial) {
      emit(CatalogLoading(categories: existingCategories, products: null));
      logger.d('State emitted: CatalogLoading');
    }
    
    // Загружаем продукты из API
    logger.i('Loading products with filters: minPrice=${event.minPrice}, maxPrice=${event.maxPrice}, categoryId=$selectedCategoryId, searchQuery=$searchQuery');
    final result = await catalogRepository.getProducts(
      businessSlug: event.businessSlug,
      categoryId: selectedCategoryId,
      searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
    );
    
    result.fold(
      (failure) {
        logger.e('Failed to load products: ${failure.message}');
        emit(CatalogError(failure.message));
      },
      (products) {
        logger.i('Loaded ${products.length} products');
        
      // Всегда эмитим CatalogLoaded с категориями и продуктами
      final loadedState = CatalogLoaded(
        categories: existingCategories ?? [],
        products: products,
        searchQuery: searchQuery,
        selectedCategoryId: selectedCategoryId,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
      );
        logger.i('About to emit CatalogLoaded: ${products.length} products, ${existingCategories?.length ?? 0} categories');
        emit(loadedState);
        logger.i('✅ State emitted: CatalogLoaded (both) with ${products.length} products');
      },
    );
  }

  void _onSearchProducts(SearchProducts event, Emitter<CatalogState> emit) async {
    logger.i('SearchProducts event received: "${event.query}"');
    
    // Preserve categories and selected category from current state
    final currentState = state;
    List<Category>? existingCategories;
    String? selectedCategoryId;
    
    // Сохраняем фильтры по цене из текущего состояния
    double? minPrice;
    double? maxPrice;
    
    if (currentState is CatalogCategoriesLoaded) {
      existingCategories = currentState.categories;
      selectedCategoryId = currentState.selectedCategoryId;
      minPrice = currentState.minPrice;
      maxPrice = currentState.maxPrice;
    } else if (currentState is CatalogLoaded) {
      existingCategories = currentState.categories;
      selectedCategoryId = currentState.selectedCategoryId;
      minPrice = currentState.minPrice;
      maxPrice = currentState.maxPrice;
    } else if (currentState is CatalogProductsLoaded) {
      existingCategories = currentState.categories;
      selectedCategoryId = currentState.selectedCategoryId;
      minPrice = currentState.minPrice;
      maxPrice = currentState.maxPrice;
    }
    
    logger.i('SearchProducts: preserving price filters minPrice=$minPrice, maxPrice=$maxPrice');
    
    // Загружаем продукты с поисковым запросом (сохраняем фильтры по цене)
    final result = await catalogRepository.getProducts(
      businessSlug: event.businessSlug,
      categoryId: selectedCategoryId,
      searchQuery: event.query.isNotEmpty ? event.query : null,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    
    result.fold(
      (failure) {
        logger.e('Failed to search products: ${failure.message}');
        emit(CatalogError(failure.message));
      },
      (products) {
        logger.i('Found ${products.length} products for query: "${event.query}" with price filters: minPrice=$minPrice, maxPrice=$maxPrice');
        
        if (existingCategories != null) {
          emit(CatalogLoaded(
            categories: existingCategories,
            products: products,
            searchQuery: event.query,
            selectedCategoryId: selectedCategoryId,
            minPrice: minPrice,
            maxPrice: maxPrice,
          ));
        } else {
          emit(CatalogProductsLoaded(
            products,
            searchQuery: event.query,
            selectedCategoryId: selectedCategoryId,
            minPrice: minPrice,
            maxPrice: maxPrice,
          ));
        }
      },
    );
  }

  void _onFilterByCategory(FilterByCategory event, Emitter<CatalogState> emit) async {
    logger.i('FilterByCategory event received: ${event.categoryId ?? "all"}');
    
    // Preserve categories and search query from current state
    final currentState = state;
    List<Category> existingCategories;
    String searchQuery = '';
    
    if (currentState is CatalogCategoriesLoaded) {
      existingCategories = currentState.categories;
      searchQuery = currentState.searchQuery;
    } else if (currentState is CatalogLoaded) {
      existingCategories = currentState.categories;
      searchQuery = currentState.searchQuery;
    } else if (currentState is CatalogProductsLoaded) {
      existingCategories = currentState.categories ?? [];
      searchQuery = currentState.searchQuery;
    } else {
      // Загружаем категории если их нет
      final categoriesResult = await catalogRepository.getCategories(event.businessSlug);
      existingCategories = categoriesResult.fold(
        (failure) => [],
        (categories) => categories,
      );
    }
    
    // Сохраняем фильтры по цене из текущего состояния
    double? minPrice = event.minPrice;
    double? maxPrice = event.maxPrice;
    if (minPrice == null || maxPrice == null) {
      if (currentState is CatalogLoaded) {
        minPrice = minPrice ?? currentState.minPrice;
        maxPrice = maxPrice ?? currentState.maxPrice;
      } else if (currentState is CatalogProductsLoaded) {
        minPrice = minPrice ?? currentState.minPrice;
        maxPrice = maxPrice ?? currentState.maxPrice;
      }
    }
    
    logger.i('FilterByCategory: using price filters minPrice=$minPrice, maxPrice=$maxPrice');
    
    // Загружаем продукты с фильтром по категории (сохраняем фильтры по цене)
    final result = await catalogRepository.getProducts(
      businessSlug: event.businessSlug,
      categoryId: event.categoryId,
      searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    
    result.fold(
      (failure) {
        logger.e('Failed to filter products: ${failure.message}');
        emit(CatalogError(failure.message));
      },
      (products) {
        logger.i('Found ${products.length} products in category: ${event.categoryId ?? "all"}');
        
        emit(CatalogLoaded(
          categories: existingCategories,
          products: products,
          searchQuery: searchQuery,
          selectedCategoryId: event.categoryId,
          minPrice: minPrice,
          maxPrice: maxPrice,
        ));
      },
    );
  }

  void _onSortProducts(SortProducts event, Emitter<CatalogState> emit) async {
    logger.i('SortProducts event received: ${event.sortType}');
    
    // Preserve existing state
    final currentState = state;
    List<Category> existingCategories;
    List<Product> products;
    String searchQuery = '';
    String? selectedCategoryId;
    double? minPrice;
    double? maxPrice;
    
    if (currentState is CatalogLoaded) {
      existingCategories = currentState.categories;
      searchQuery = currentState.searchQuery;
      selectedCategoryId = currentState.selectedCategoryId;
      minPrice = currentState.minPrice;
      maxPrice = currentState.maxPrice;
      
      // Для сортировки используем уже загруженные товары
      products = List<Product>.from(currentState.products);
    } else if (currentState is CatalogProductsLoaded) {
      existingCategories = currentState.categories ?? [];
      searchQuery = currentState.searchQuery;
      selectedCategoryId = currentState.selectedCategoryId;
      minPrice = currentState.minPrice;
      maxPrice = currentState.maxPrice;
      
      // Если категории отсутствуют, загружаем их
      if (existingCategories.isEmpty) {
        final categoriesResult = await catalogRepository.getCategories(event.businessSlug);
        existingCategories = categoriesResult.fold(
          (failure) => [],
          (categories) => categories,
        );
      }
      
      // Для сортировки используем уже загруженные товары
      products = List<Product>.from(currentState.products);
    } else if (currentState is CatalogCategoriesLoaded) {
      existingCategories = currentState.categories;
      searchQuery = currentState.searchQuery;
      selectedCategoryId = currentState.selectedCategoryId;
      minPrice = currentState.minPrice;
      maxPrice = currentState.maxPrice;
      
      // Загружаем продукты с текущими фильтрами (включая фильтры по цене)
      final result = await catalogRepository.getProducts(
        businessSlug: event.businessSlug,
        categoryId: selectedCategoryId,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );
      
      products = result.fold(
        (failure) => [],
        (products) => products,
      );
    } else {
      // Загружаем категории и продукты
      final categoriesResult = await catalogRepository.getCategories(event.businessSlug);
      existingCategories = categoriesResult.fold(
        (failure) => [],
        (categories) => categories,
      );
      
      final productsResult = await catalogRepository.getProducts(
        businessSlug: event.businessSlug,
      );
      
      products = productsResult.fold(
        (failure) => [],
        (products) => products,
      );
    }
    
    // Применяем сортировку (пропускаем 'all', так как он должен сбрасывать сортировку)
    if (event.sortType != 'all') {
      switch (event.sortType) {
        case 'price_asc':
          // Сортировка по возрастанию цены
          products.sort((a, b) {
            final priceComparison = a.price.compareTo(b.price);
            // Если цены равны, сортируем по названию для стабильности
            if (priceComparison == 0) {
              return a.title.compareTo(b.title);
            }
            return priceComparison;
          });
          logger.i('Sorted ${products.length} products by price ASC');
          break;
        case 'price_desc':
          // Сортировка по убыванию цены
          products.sort((a, b) {
            final priceComparison = b.price.compareTo(a.price);
            // Если цены равны, сортируем по названию для стабильности
            if (priceComparison == 0) {
              return a.title.compareTo(b.title);
            }
            return priceComparison;
          });
          logger.i('Sorted ${products.length} products by price DESC');
          break;
        default:
          // Без сортировки или сортировка по умолчанию
          products.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
      }
    } else {
      // Для 'all' - сортировка по умолчанию (по дате создания)
      products.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    // Логируем первые несколько цен для отладки
    if (products.isNotEmpty) {
      final prices = products.map((p) => p.price).toList();
      logger.i('First 5 prices after sort: ${prices.take(5).toList()}');
    }
    
    emit(CatalogLoaded(
      categories: existingCategories,
      products: products,
      searchQuery: searchQuery,
      selectedCategoryId: selectedCategoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
    ));
  }
}

