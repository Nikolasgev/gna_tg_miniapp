import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tg_store/admin_panel/presentation/screens/login_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/products_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/categories_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/orders_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/settings_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/promocodes_screen.dart';
import 'package:tg_store/admin_panel/presentation/screens/analytics_screen.dart';
import 'package:tg_store/admin_panel/application/bloc/analytics/analytics_bloc.dart';
import 'package:tg_store/admin_panel/data/repositories/analytics_repository_impl.dart';
import 'package:tg_store/admin_panel/data/repositories/admin_auth_repository.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  final _authRepository = AdminAuthRepository();
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isAuth = await _authRepository.isAuthenticated();
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    // Если авторизован - показываем админ-панель, иначе - экран логина
    return _isAuthenticated
        ? const AdminDashboardScreen()
        : const LoginScreen();
  }
}

/// Главный экран админ-панели (показывается после успешной авторизации)
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authRepository = AdminAuthRepository();
  String? _businessSlug;
  String? _businessName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
  }

  Future<void> _loadBusinessInfo() async {
    final slug = await _authRepository.getBusinessSlug();
    final name = await _authRepository.getBusinessName();
    
    if (mounted) {
      setState(() {
        _businessSlug = slug ?? 'default-business';
        _businessName = name ?? 'Мой магазин';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authRepository.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final businessSlug = _businessSlug ?? 'default-business';
    final businessName = _businessName ?? 'Мой магазин';

    return Scaffold(
      appBar: AppBar(
        title: Text(businessName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            children: [
          _buildMenuCard(
            context,
            icon: Icons.inventory_2,
            title: 'Товары',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductsScreen(
                    businessSlug: businessSlug,
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.category,
            title: 'Категории',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoriesScreen(
                    businessSlug: businessSlug,
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.shopping_cart,
            title: 'Заказы',
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrdersScreen(
                    businessSlug: businessSlug,
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.local_offer,
            title: 'Промокоды',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PromocodesScreen(
                    businessSlug: businessSlug,
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.bar_chart,
            title: 'Аналитика',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => AnalyticsBloc(
                      analyticsRepository: AnalyticsRepositoryImpl(),
                    ),
                    child: AnalyticsScreen(
                      businessSlug: businessSlug,
                    ),
                  ),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            icon: Icons.settings,
            title: 'Настройки',
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    businessSlug: businessSlug,
                  ),
                ),
              );
            },
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 300,
        maxHeight: 200,
      ),
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

