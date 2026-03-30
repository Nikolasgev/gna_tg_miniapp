import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tg_store/core/utils/telegram_webapp.dart';
import 'package:tg_store/core/services/business_service.dart';
import 'package:tg_store/mini_app/application/bloc/auth/auth_bloc.dart';
import 'package:tg_store/mini_app/presentation/navigation/app_router.dart';

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    // Get init_data from Telegram WebApp
    final initData = TelegramWebApp.getInitData();
    
    // Get business_slug from URL or init_data
    final businessSlug = await _extractBusinessSlug();

    // If running outside Telegram or init_data is empty, use mock data for development
    if (initData == null || initData.isEmpty || initData.trim().isEmpty) {
      // Development mode - skip validation and go directly to catalog
      // In production, this should show an error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppRouter.toCatalog();
        }
      });
      return;
    }

    // Trigger validation
    context.read<AuthBloc>().add(
          ValidateInitData(
            initData: initData,
            businessSlug: businessSlug,
          ),
        );
  }

  Future<String> _extractBusinessSlug() async {
    // Пытаемся получить из сохраненного значения
    final savedSlug = await BusinessService.getBusinessSlug();
    if (savedSlug != null && savedSlug.isNotEmpty) {
      return savedSlug;
    }

    // Пытаемся извлечь из URL
    // TODO: Extract from URL or init_data
    // For example: https://example.com/mini_app?business=my-store
    // Or from init_data unsafe parameters
    
    // По умолчанию используем 'default-business' для разработки
    const defaultSlug = 'default-business';
    await BusinessService.setBusinessSlug(defaultSlug);
    return defaultSlug;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Navigate to catalog
          AppRouter.toCatalog();
        } else if (state is AuthError) {
          // Show error and retry option
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ошибка инициализации. Проверьте подключение к интернету.'),
              action: SnackBarAction(
                label: 'Повторить',
                onPressed: _initializeApp,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        // In development mode (no Telegram), show loading briefly then navigate
        final initData = TelegramWebApp.getInitData();
        if (initData == null) {
          // Development mode - show loading briefly
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AuthError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка инициализации',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Проверьте подключение к интернету и попробуйте еще раз.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initializeApp,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }

        // Initial state - show loading
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

