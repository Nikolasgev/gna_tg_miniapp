import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tg_store/core/config/environment.dart';
import 'package:tg_store/core/theme/app_theme.dart';
import 'package:tg_store/admin_panel/presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Устанавливаем окружение на основе переменных окружения
  final apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: '');
  final envString = const String.fromEnvironment('ENVIRONMENT', defaultValue: '');
  final isProduction = apiBaseUrl.isNotEmpty || envString == 'production';
  
  if (isProduction) {
    AppConfig.setEnvironment(Environment.production);
  } else {
    AppConfig.setEnvironment(Environment.development);
  }
  
  runApp(const AdminPanelApp());
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AdminApp(),
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

