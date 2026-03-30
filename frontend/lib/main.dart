// Default entry point - redirects to Mini App
// To run Mini App: flutter run -d chrome --target lib/mini_app/main.dart
// To run Admin Panel: flutter run -d chrome --target lib/admin_panel/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/theme/app_theme.dart';
import 'package:tg_store/mini_app/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Set environment
  AppConfig.setEnvironment(Environment.development);
  
  // Run Mini App by default
  runApp(const MiniApp());
}

class MiniApp extends StatelessWidget {
  const MiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telegram Mini App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const App(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
    );
  }
}
