import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/presentation/screens/cart_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/catalog_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/checkout_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/initialization_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/order_detail_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/orders_history_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/product_detail_screen.dart';
import 'package:tg_store/mini_app/presentation/screens/loyalty_screen.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false, // We use our own logging
    routes: [
      GoRoute(
        path: '/',
        name: 'initialization',
        builder: (context, state) {
          _logNavigation(state);
          return const InitializationScreen();
        },
      ),
      GoRoute(
        path: '/catalog',
        name: 'catalog',
        builder: (context, state) {
          _logNavigation(state);
          return const CatalogScreen();
        },
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product',
        builder: (context, state) {
          _logNavigation(state);
          final productId = state.pathParameters['id'] ?? '';
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) {
          _logNavigation(state);
          return const CartScreen();
        },
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) {
          _logNavigation(state);
          return const CheckoutScreen();
        },
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) {
          _logNavigation(state);
          return const OrdersHistoryScreen();
        },
      ),
      GoRoute(
        path: '/loyalty',
        name: 'loyalty',
        builder: (context, state) {
          _logNavigation(state);
          return const LoyaltyScreen();
        },
      ),
    ],
    errorBuilder: (context, state) {
      logger.e('Navigation error: ${state.error}');
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Страница не найдена: ${state.uri}'),
            ],
          ),
        ),
      );
    },
  );

  static void _logNavigation(GoRouterState state) {
    logger.i(
      'Navigation: ${state.uri}',
    );
    
    if (state.pathParameters.isNotEmpty) {
      logger.d(
        'Path params: ${state.pathParameters}',
      );
    }
    
    if (state.uri.queryParameters.isNotEmpty) {
      logger.d(
        'Query params: ${state.uri.queryParameters}',
      );
    }
  }

  static GoRouter get router => _router;

  // Navigation helpers with logging
  static void push(String path, {Object? extra}) {
    logger.i('Navigating to: $path');
    _router.push(path, extra: extra);
  }

  static void pushReplacement(String path, {Object? extra}) {
    logger.i('Replacing with: $path');
    _router.pushReplacement(path, extra: extra);
  }

  static void go(String path, {Object? extra}) {
    logger.i('Going to: $path');
    _router.go(path, extra: extra);
  }

  static void pop<T>([T? result]) {
    logger.i('Navigating back');
    _router.pop(result);
  }

  // Convenience methods for specific routes
  static void toCatalog() {
    go('/catalog');
  }
  
  static void toInitialization() {
    go('/');
  }

  static void toProduct(String productId) {
    push('/product/$productId');
  }

  static void toCart() {
    push('/cart');
  }

  static void toCheckout() {
    push('/checkout');
  }

  static void toOrders() {
    push('/orders');
  }

  /// Navigate to order detail screen using Navigator.push (not go_router)
  /// This is used because OrderDetailScreen is opened via MaterialPageRoute
  static void toOrderDetail(BuildContext context, String orderId) {
    logger.i('Navigating to order detail: $orderId');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: orderId),
      ),
    );
  }
}
