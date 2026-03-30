import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/presentation/app.dart';

void main() async {
  logger.i('🚀 Starting application initialization');
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    logger.i('WidgetsFlutterBinding initialized');
    
    // Initialize Hive for local storage
    // Note: Hive.initFlutter() may not work on Web, use try-catch
    try {
      logger.i('Initializing Hive...');
      await Hive.initFlutter();
      logger.i('Hive initialized successfully');
    } catch (e, stackTrace) {
      // Hive may not be fully supported on Web, continue without it
      logger.w('Hive initialization skipped (Web compatibility)', 
        error: e,
        stackTrace: stackTrace,
      );
    }
    
    // Register Hive adapters
    // TODO: Register adapters for Cart, Product, etc.
    
    // Set environment (can be changed based on build configuration)
    // Для production используем production environment
    final apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
    final isProduction = apiBaseUrl.isNotEmpty || 
        (const String.fromEnvironment('ENVIRONMENT', defaultValue: '') == 'production');
    
    if (isProduction) {
      logger.i('Setting environment to production');
      AppConfig.setEnvironment(Environment.production);
    } else {
      logger.i('Setting environment to development');
      AppConfig.setEnvironment(Environment.development);
    }
    logger.i('Environment configured: ${AppConfig.baseUrl}');
    
    logger.i('Running MiniApp...');
    runApp(const MiniApp());
    logger.i('MiniApp started');
  } catch (e, stackTrace) {
    logger.e('Fatal error during initialization', 
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

class MiniApp extends StatelessWidget {
  const MiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App(key: App.appStateKey);
  }
}

