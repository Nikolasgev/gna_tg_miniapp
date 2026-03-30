import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tg_store/core/theme/app_theme.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/core/services/theme_service.dart';
import 'package:tg_store/core/services/business_theme_service.dart';
import 'package:tg_store/core/theme/business_theme.dart';
import 'package:tg_store/mini_app/application/bloc/auth/auth_bloc.dart';
import 'package:tg_store/mini_app/presentation/bloc/cart/cart_bloc.dart';
import 'package:tg_store/mini_app/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:tg_store/mini_app/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:tg_store/mini_app/presentation/bloc/orders/orders_bloc.dart';
import 'package:tg_store/mini_app/presentation/bloc/product/product_bloc.dart';
import 'package:tg_store/mini_app/data/repositories/auth_repository_impl.dart';
import 'package:tg_store/mini_app/data/repositories/order_repository_impl.dart';
import 'package:tg_store/mini_app/presentation/navigation/app_router.dart';
import 'package:tg_store/mini_app/data/repositories/catalog_repository_impl.dart';
import 'package:tg_store/mini_app/data/repositories/loyalty_repository_impl.dart';
import 'package:tg_store/mini_app/application/bloc/loyalty/loyalty_bloc.dart';
import 'package:tg_store/l10n/app_localizations.dart';

class App extends StatefulWidget {
  const App({super.key});

  static final GlobalKey<_AppState> appStateKey = GlobalKey<_AppState>();

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _locale;
  BusinessTheme? _businessTheme;
  bool _isLoading = true;
  final BusinessThemeService _businessThemeService = BusinessThemeService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Загружаем пользовательские настройки (тема и локаль)
      final themeMode = await ThemeService.getThemeMode();
      final locale = await ThemeService.getLocale();
      
      // Загружаем тему бизнеса с бекенда
      final businessTheme = await _businessThemeService.loadBusinessTheme();
      
      if (mounted) {
        setState(() {
          _themeMode = themeMode;
          _locale = locale;
          _businessTheme = businessTheme;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      logger.e('Error loading app settings', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void updateThemeMode(ThemeMode newThemeMode) {
    setState(() {
      _themeMode = newThemeMode;
    });
  }

  void updateLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    logger.i('Building App widget with theme: $_themeMode, locale: $_locale');
    
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) {
            logger.i('Creating AuthBloc');
            return AuthBloc(
              authRepository: AuthRepositoryImpl(),
            );
          },
        ),
        BlocProvider<CartBloc>(
          create: (context) {
            logger.i('Creating CartBloc');
            return CartBloc();
          },
        ),
        BlocProvider<CatalogBloc>(
          create: (context) {
            logger.i('Creating CatalogBloc');
            return CatalogBloc(
              catalogRepository: CatalogRepositoryImpl(),
            );
          },
        ),
        BlocProvider<ProductBloc>(
          create: (context) {
            logger.i('Creating ProductBloc');
            return ProductBloc(
              catalogRepository: CatalogRepositoryImpl(),
            );
          },
        ),
        BlocProvider<CheckoutBloc>(
          create: (context) {
            logger.i('Creating CheckoutBloc');
            return CheckoutBloc(
              orderRepository: OrderRepositoryImpl(),
            );
          },
        ),
        BlocProvider<OrdersBloc>(
          create: (context) {
            logger.i('Creating OrdersBloc');
            return OrdersBloc(
              orderRepository: OrderRepositoryImpl(),
            );
          },
        ),
        BlocProvider<LoyaltyBloc>(
          create: (context) {
            logger.i('Creating LoyaltyBloc');
            return LoyaltyBloc(
              loyaltyRepository: LoyaltyRepositoryImpl(),
            );
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Telegram Mini App',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: _businessTheme?.hasCustomColors == true
            ? AppTheme.createLightTheme(_businessTheme!)
            : AppTheme.lightTheme,
        darkTheme: _businessTheme?.hasCustomColors == true
            ? AppTheme.createDarkTheme(_businessTheme!)
            : AppTheme.darkTheme,
        locale: _locale, // Установленная локаль
        routerConfig: AppRouter.router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}
