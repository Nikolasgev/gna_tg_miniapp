import 'package:flutter/material.dart';
import 'package:tg_store/l10n/app_localizations.dart';
import 'package:tg_store/core/services/theme_service.dart';
import 'package:tg_store/core/services/business_service.dart';
import 'package:tg_store/core/services/business_theme_service.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/presentation/app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _selectedLocale;
  String? _currentBusinessSlug;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final themeMode = await ThemeService.getThemeMode();
      final locale = await ThemeService.getLocale();
      final businessSlug = await BusinessService.getBusinessSlug();
      
      if (mounted) {
        setState(() {
          _themeMode = themeMode;
          _selectedLocale = locale;
          _currentBusinessSlug = businessSlug ?? 'default-business';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      logger.e('Error loading settings', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateThemeMode(ThemeMode newThemeMode) async {
    await ThemeService.setThemeMode(newThemeMode);
    setState(() {
      _themeMode = newThemeMode;
    });
    
    // Уведомляем App об изменении темы
    if (mounted) {
      final appState = App.appStateKey.currentState;
      if (appState != null) {
        appState.updateThemeMode(newThemeMode);
      }
    }
  }

  Future<void> _updateLocale(Locale newLocale) async {
    await ThemeService.setLocale(newLocale);
    setState(() {
      _selectedLocale = newLocale;
    });
    
    // Уведомляем App об изменении локали
    if (mounted) {
      final appState = App.appStateKey.currentState;
      if (appState != null) {
        appState.updateLocale(newLocale);
      }
    }
  }
  
  Future<void> _switchBusiness(String newSlug) async {
    await BusinessService.setBusinessSlug(newSlug);
    
    // Очищаем кэш темы бизнеса
    final businessThemeService = BusinessThemeService();
    businessThemeService.clearCache();
    
    // Показываем сообщение
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Бизнес изменен на: $newSlug. Перезапустите приложение.'),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Перезагружаем настройки
      setState(() {
        _currentBusinessSlug = newSlug;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentLocale = _selectedLocale ?? 
        Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Тема
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.appearance,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppLocalizations.of(context)!.lightTheme),
                  subtitle: Text(AppLocalizations.of(context)!.useLightColorScheme),
                  value: ThemeMode.light,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppLocalizations.of(context)!.darkTheme),
                  subtitle: Text(AppLocalizations.of(context)!.useDarkColorScheme),
                  value: ThemeMode.dark,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppLocalizations.of(context)!.systemTheme),
                  subtitle: Text(AppLocalizations.of(context)!.followSystemSettings),
                  value: ThemeMode.system,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateThemeMode(value);
                    }
                  },
                ),
                const Divider(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Переключение бизнеса (для тестирования)
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Переключение бизнеса (тест)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Текущий: ${_currentBusinessSlug ?? "не установлен"}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Кофейня (default-business)'),
                  subtitle: const Text('Кофе, десерты, напитки'),
                  value: 'default-business',
                  groupValue: _currentBusinessSlug,
                  onChanged: (value) {
                    if (value != null) {
                      _switchBusiness(value);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Косметика для волос (hair-cosmetics)'),
                  subtitle: const Text('Шампуни, маски, средства для волос'),
                  value: 'hair-cosmetics',
                  groupValue: _currentBusinessSlug,
                  onChanged: (value) {
                    if (value != null) {
                      _switchBusiness(value);
                    }
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '⚠️ После переключения перезапустите приложение',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Локализация
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.language,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                RadioListTile<String>(
                  title: Text(AppLocalizations.of(context)!.russian),
                  value: 'ru',
                  groupValue: currentLocale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateLocale(Locale(value, 'RU'));
                    }
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppLocalizations.of(context)!.english),
                  value: 'en',
                  groupValue: currentLocale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateLocale(Locale(value, 'US'));
                    }
                  },
                ),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
