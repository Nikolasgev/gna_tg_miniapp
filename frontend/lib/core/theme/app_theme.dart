import 'package:flutter/material.dart';
import 'package:tg_store/core/theme/business_theme.dart';

class AppTheme {
  // ========== СВЕТЛАЯ ТЕМА ==========
  // Primary
  static const Color _lightPrimaryColor = Color(0xFF6B4D3C); // Тёплый кофейный коричневый
  static const Color _lightPrimaryVariant = Color(0xFF523A2D); // Более глубокий оттенок
  
  // Secondary
  static const Color _lightSecondaryColor = Color(0xFFF3E8DD); // Кремово-молочный
  static const Color _lightSecondaryVariant = Color(0xFFE7D6C2); // Тёплый беж
  
  // Accent
  static const Color _lightAccentColor = Color(0xFFD8A25E); // Золотистый карамельный
  
  // Фоновые цвета (светлая тема)
  static const Color _lightBackground = Color(0xFFFAF7F3); // Тёплый светлый
  static const Color _lightSurface = Color(0xFFF0E7DE); // Мягкий кремовый
  static const Color _lightCardBackground = Color(0xFFEFE7E0); // Нейтрально-песочный
  
  // Текстовые цвета (светлая тема)
  static const Color _lightPrimaryText = Color(0xFF3B2A1F); // Тёмно-коричневый
  static const Color _lightSecondaryText = Color(0xFF6A6057); // Средний тёплый серый
  static const Color _lightMutedText = Color(0xFFB1A79F); // Светлый серо-бежевый
  
  // Состояния UI (светлая тема)
  static const Color _lightSuccess = Color(0xFF77C59B); // Зелёный мятный
  static const Color _lightWarning = Color(0xFFE8B25D); // Мягкий янтарный
  static const Color _lightError = Color(0xFFB64B4B); // Гранатовый
  static const Color _lightDisabled = Color(0xFFCFC7C0); // Бледный бежево-серый

  // ========== ТЕМНАЯ ТЕМА ==========
  // Primary
  static const Color _darkPrimaryColor = Color(0xFFD8A25E); // Глубокий шоколадный
  static const Color _darkPrimaryContainer = Color(0xFF3C2A21); // Тёмный кофейно-коричневый
  
  // Secondary
  static const Color _darkSecondaryColor = Color(0xFFE6D6C8); // Мягкий кремовый
  static const Color _darkSecondaryContainer = Color(0xFF4C3A2F); // Какао
  
  // Accent
  static const Color _darkAccentColor = Color(0xFFE6B878); // Золотисто-карамельный
  
  // Фоновые цвета (темная тема)
  static const Color _darkBackground = Color(0xFF18120E); // Почти чёрный с кофейным подтоном
  static const Color _darkSurface = Color(0xFF221A15); // Очень тёмный коричнево-графитовый
  static const Color _darkSurfaceVariant = Color(0xFF2E2119); // Насыщенный эспрессо
  static const Color _darkCardBackground = Color(0xFF2A1F18); // Матовый тёмный мокко
  
  // Текстовые цвета (темная тема)
  static const Color _darkPrimaryText = Color(0xFFF3E8DD); // Тёплый кремово-белый
  static const Color _darkSecondaryText = Color(0xFFC8BEB6); // Бежево-серый
  static const Color _darkTertiaryText = Color(0xFFA4978C); // Мягкий кофейный серый
  static const Color _darkMutedText = Color(0xFF7A6F67); // Приглушённый серо-коричневый
  
  // Состояния UI (темная тема)
  static const Color _darkSuccess = Color(0xFF89D3AC); // Мягкий мятный зелёный
  static const Color _darkWarning = Color(0xFFE3AA58); // Янтарный
  static const Color _darkError = Color(0xFF9E3F3F); // Темный гранатовый
  static const Color _darkDisabled = Color(0xFF5B514C); // Тусклый кофейный серый

  // Светлая тема
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _lightPrimaryColor,
      onPrimary: Colors.white,
      primaryContainer: _lightSecondaryColor, // Светлый контейнер для лучшей читаемости
      onPrimaryContainer: _lightPrimaryColor, // Темный текст на светлом фоне
      secondary: _lightSecondaryColor,
      onSecondary: _lightPrimaryText,
      secondaryContainer: _lightSecondaryVariant,
      onSecondaryContainer: _lightPrimaryText,
      tertiary: _lightAccentColor,
      onTertiary: Colors.white,
      error: _lightError,
      onError: Colors.white,
      errorContainer: _lightError.withOpacity(0.1), // Светлый контейнер ошибки
      onErrorContainer: _lightError, // Темный текст ошибки на светлом фоне
      surface: _lightSurface,
      onSurface: _lightPrimaryText,
      onSurfaceVariant: _lightSecondaryText,
      surfaceContainerHighest: _lightCardBackground,
      surfaceContainerHigh: _lightCardBackground,
      outline: _lightMutedText,
      outlineVariant: _lightDisabled,
      shadow: Colors.black.withOpacity(0.1),
      scrim: Colors.black.withOpacity(0.3),
      inverseSurface: _lightPrimaryText,
      onInverseSurface: _lightBackground,
      inversePrimary: _lightPrimaryColor.withOpacity(0.2),
      surfaceTint: _lightPrimaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _lightBackground,
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _lightSurface,
        foregroundColor: _lightPrimaryText,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.1),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightPrimaryText,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: _lightPrimaryText,
          size: 24,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _lightMutedText.withOpacity(0.2),
            width: 1,
          ),
        ),
        color: _lightCardBackground,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _lightMutedText.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _lightMutedText.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _lightPrimaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _lightError,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: _lightMutedText.withOpacity(0.6),
          fontSize: 14,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _lightPrimaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith<double>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return 0;
              }
              return 0;
            },
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _lightPrimaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: _lightPrimaryColor,
            width: 1.5,
          ),
          foregroundColor: _lightPrimaryColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _lightPrimaryText,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _lightPrimaryText,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _lightPrimaryText,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _lightPrimaryText,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _lightPrimaryText,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _lightPrimaryText,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _lightPrimaryText,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _lightPrimaryText,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _lightPrimaryText,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: _lightPrimaryText,
          letterSpacing: 0.15,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: _lightPrimaryText,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: _lightSecondaryText,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _lightPrimaryText,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _lightPrimaryText,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _lightSecondaryText,
          letterSpacing: 0.5,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurface,
        selectedColor: _lightPrimaryColor.withOpacity(0.2),
        disabledColor: _lightDisabled,
        labelStyle: TextStyle(
          color: _lightPrimaryText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: _lightPrimaryColor, // Цвет текста для выбранного чипса
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: _lightMutedText.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: _lightPrimaryText,
        size: 24,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _lightPrimaryColor,
        unselectedItemColor: _lightSecondaryText,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _lightPrimaryColor,
        linearTrackColor: _lightPrimaryColor.withOpacity(0.2),
        circularTrackColor: _lightPrimaryColor.withOpacity(0.2),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightPrimaryColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _darkPrimaryColor,
      onPrimary: _darkBackground,
      primaryContainer: _darkPrimaryContainer,
      onPrimaryContainer: _darkPrimaryText,
      secondary: _darkSecondaryColor,
      onSecondary: _darkBackground,
      secondaryContainer: _darkSecondaryContainer,
      onSecondaryContainer: _darkPrimaryText,
      tertiary: _darkAccentColor,
      onTertiary: _darkBackground,
      error: _darkError,
      onError: _darkPrimaryText,
      errorContainer: _darkError.withOpacity(0.2), // Темный контейнер ошибки
      onErrorContainer: _darkError, // Светлый текст ошибки на темном фоне
      surface: _darkSurface,
      onSurface: _darkPrimaryText,
      onSurfaceVariant: _darkSecondaryText,
      surfaceContainerHighest: _darkSurfaceVariant,
      surfaceContainerHigh: _darkCardBackground,
      outline: _darkMutedText,
      outlineVariant: _darkDisabled,
      shadow: Colors.black.withOpacity(0.6),
      scrim: Colors.black.withOpacity(0.8),
      inverseSurface: _darkPrimaryText,
      onInverseSurface: _darkBackground,
      inversePrimary: _darkPrimaryColor.withOpacity(0.2),
      surfaceTint: _darkPrimaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkBackground,
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _darkSurface,
        foregroundColor: _darkPrimaryText,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.6),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkPrimaryText,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: _darkPrimaryText,
          size: 24,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _darkMutedText.withOpacity(0.2),
            width: 1,
          ),
        ),
        color: _darkCardBackground,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _darkMutedText.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _darkMutedText.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _darkPrimaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _darkError,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: _darkTertiaryText.withOpacity(0.6),
          fontSize: 14,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _darkPrimaryColor,
          foregroundColor: _darkBackground,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith<double>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return 0;
              }
              return 0;
            },
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _darkPrimaryColor,
          foregroundColor: _darkBackground,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: _darkPrimaryColor,
            width: 1.5,
          ),
          foregroundColor: _darkPrimaryColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _darkPrimaryText,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: _darkPrimaryText,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _darkPrimaryText,
          letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _darkPrimaryText,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _darkPrimaryText,
          letterSpacing: -0.5,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkPrimaryText,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _darkPrimaryText,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _darkPrimaryText,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _darkPrimaryText,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: _darkPrimaryText,
          letterSpacing: 0.15,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: _darkPrimaryText,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: _darkSecondaryText,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _darkPrimaryText,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _darkPrimaryText,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _darkSecondaryText,
          letterSpacing: 0.5,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurfaceVariant,
        selectedColor: _darkPrimaryColor.withOpacity(0.2),
        disabledColor: _darkDisabled,
        labelStyle: TextStyle(
          color: _darkPrimaryText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: _darkPrimaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: _darkMutedText.withOpacity(0.3),
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: _darkPrimaryText,
        size: 24,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: _darkBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _darkPrimaryColor,
        unselectedItemColor: _darkSecondaryText,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _darkPrimaryColor,
        linearTrackColor: _darkPrimaryColor.withOpacity(0.2),
        circularTrackColor: _darkPrimaryColor.withOpacity(0.2),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkPrimaryColor,
        contentTextStyle: TextStyle(
          color: _darkBackground,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
    );
  }

  // Геттеры для доступа к цветам из темы (темная тема по умолчанию для обратной совместимости)
  static Color get primaryColor => _darkPrimaryColor;
  static Color get primaryContainer => _darkPrimaryContainer;
  static Color get secondaryColor => _darkSecondaryColor;
  static Color get secondaryContainer => _darkSecondaryContainer;
  static Color get accentColor => _darkAccentColor;
  static Color get background => _darkBackground;
  static Color get surface => _darkSurface;
  static Color get surfaceVariant => _darkSurfaceVariant;
  static Color get cardBackground => _darkCardBackground;
  static Color get primaryText => _darkPrimaryText;
  static Color get secondaryText => _darkSecondaryText;
  static Color get tertiaryText => _darkTertiaryText;
  static Color get mutedText => _darkMutedText;
  static Color get success => _darkSuccess;
  static Color get warning => _darkWarning;
  static Color get error => _darkError;
  static Color get disabled => _darkDisabled;

  /// Создать светлую тему с кастомными цветами бизнеса
  static ThemeData createLightTheme(BusinessTheme businessTheme) {
    // Используем цвета бизнеса, если они заданы, иначе дефолтные
    final primaryColor = businessTheme.primaryColor ?? _lightPrimaryColor;
    final backgroundColor = businessTheme.backgroundColor ?? _lightBackground;
    final textColor = businessTheme.textColor ?? _lightPrimaryText;
    final secondaryColor = businessTheme.secondaryColor ?? _lightSecondaryColor;
    final tertiaryColor = businessTheme.tertiaryColor ?? _lightAccentColor;
    final errorColor = businessTheme.errorColor ?? _lightError;
    final surfaceColor = businessTheme.surfaceColor ?? _lightSurface;
    final onPrimaryColor = businessTheme.onPrimaryColor ?? Colors.white;
    final onSecondaryColor = businessTheme.onSecondaryColor ?? textColor;
    final onTertiaryColor = businessTheme.onTertiaryColor ?? Colors.white;
    final onErrorColor = businessTheme.onErrorColor ?? Colors.white;
    final onSurfaceColor = businessTheme.onSurfaceColor ?? textColor;
    final primaryContainerColor = businessTheme.primaryContainerColor ?? _lightSecondaryColor;
    final secondaryContainerColor = businessTheme.secondaryContainerColor ?? _lightSecondaryVariant;
    final tertiaryContainerColor = businessTheme.tertiaryContainerColor ?? _lightSecondaryVariant;
    final errorContainerColor = businessTheme.errorContainerColor ?? _lightError.withOpacity(0.1);
    final onPrimaryContainerColor = businessTheme.onPrimaryContainerColor ?? primaryColor;
    final onSecondaryContainerColor = businessTheme.onSecondaryContainerColor ?? textColor;
    final onTertiaryContainerColor = businessTheme.onTertiaryContainerColor ?? textColor;
    final onErrorContainerColor = businessTheme.onErrorContainerColor ?? _lightError;
    final outlineColor = businessTheme.outlineColor ?? _lightMutedText;
    final outlineVariantColor = businessTheme.outlineVariantColor ?? _lightDisabled;
    
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: onPrimaryColor,
      primaryContainer: primaryContainerColor,
      onPrimaryContainer: onPrimaryContainerColor,
      secondary: secondaryColor,
      onSecondary: onSecondaryColor,
      secondaryContainer: secondaryContainerColor,
      onSecondaryContainer: onSecondaryContainerColor,
      tertiary: tertiaryColor,
      onTertiary: onTertiaryColor,
      error: errorColor,
      onError: onErrorColor,
      errorContainer: errorContainerColor,
      onErrorContainer: onErrorContainerColor,
      surface: surfaceColor,
      onSurface: onSurfaceColor,
      onSurfaceVariant: _lightSecondaryText,
      surfaceContainerHighest: _lightCardBackground,
      surfaceContainerHigh: _lightCardBackground,
      outline: outlineColor,
      outlineVariant: outlineVariantColor,
      shadow: Colors.black.withOpacity(0.1),
      scrim: Colors.black.withOpacity(0.3),
      inverseSurface: textColor,
      onInverseSurface: backgroundColor,
      inversePrimary: primaryColor.withOpacity(0.2),
      surfaceTint: primaryColor,
    );

    return lightTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
    );
  }

  /// Создать темную тему с кастомными цветами бизнеса
  static ThemeData createDarkTheme(BusinessTheme businessTheme) {
    // Используем цвета бизнеса, если они заданы, иначе дефолтные
    final primaryColor = businessTheme.primaryColor ?? _darkPrimaryColor;
    final backgroundColor = businessTheme.backgroundColor ?? _darkBackground;
    final textColor = businessTheme.textColor ?? _darkPrimaryText;
    final secondaryColor = businessTheme.secondaryColor ?? _darkSecondaryColor;
    final tertiaryColor = businessTheme.tertiaryColor ?? _darkAccentColor;
    final errorColor = businessTheme.errorColor ?? _darkError;
    final surfaceColor = businessTheme.surfaceColor ?? _darkSurface;
    final onPrimaryColor = businessTheme.onPrimaryColor ?? backgroundColor;
    final onSecondaryColor = businessTheme.onSecondaryColor ?? backgroundColor;
    final onTertiaryColor = businessTheme.onTertiaryColor ?? backgroundColor;
    final onErrorColor = businessTheme.onErrorColor ?? Colors.white;
    final onSurfaceColor = businessTheme.onSurfaceColor ?? textColor;
    final primaryContainerColor = businessTheme.primaryContainerColor ?? _darkPrimaryContainer;
    final secondaryContainerColor = businessTheme.secondaryContainerColor ?? _darkSecondaryContainer;
    final tertiaryContainerColor = businessTheme.tertiaryContainerColor ?? _darkSecondaryContainer;
    final errorContainerColor = businessTheme.errorContainerColor ?? _darkError.withOpacity(0.2);
    final onPrimaryContainerColor = businessTheme.onPrimaryContainerColor ?? textColor;
    final onSecondaryContainerColor = businessTheme.onSecondaryContainerColor ?? textColor;
    final onTertiaryContainerColor = businessTheme.onTertiaryContainerColor ?? textColor;
    final onErrorContainerColor = businessTheme.onErrorContainerColor ?? _darkError;
    final outlineColor = businessTheme.outlineColor ?? _darkMutedText;
    final outlineVariantColor = businessTheme.outlineVariantColor ?? _darkDisabled;
    
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: onPrimaryColor,
      primaryContainer: primaryContainerColor,
      onPrimaryContainer: onPrimaryContainerColor,
      secondary: secondaryColor,
      onSecondary: onSecondaryColor,
      secondaryContainer: secondaryContainerColor,
      onSecondaryContainer: onSecondaryContainerColor,
      tertiary: tertiaryColor,
      onTertiary: onTertiaryColor,
      error: errorColor,
      onError: onErrorColor,
      errorContainer: errorContainerColor,
      onErrorContainer: onErrorContainerColor,
      surface: surfaceColor,
      onSurface: onSurfaceColor,
      onSurfaceVariant: _darkSecondaryText,
      surfaceContainerHighest: _darkCardBackground,
      surfaceContainerHigh: _darkCardBackground,
      outline: outlineColor,
      outlineVariant: outlineVariantColor,
      shadow: Colors.black.withOpacity(0.3),
      scrim: Colors.black.withOpacity(0.5),
      inverseSurface: textColor,
      onInverseSurface: backgroundColor,
      inversePrimary: primaryColor.withOpacity(0.2),
      surfaceTint: primaryColor,
    );

    return darkTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: darkTheme.appBarTheme.copyWith(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
    );
  }

  /// Осветлить цвет
  static Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    return Color.fromARGB(
      color.alpha,
      ((color.red + (255 - color.red) * amount).round()).clamp(0, 255),
      ((color.green + (255 - color.green) * amount).round()).clamp(0, 255),
      ((color.blue + (255 - color.blue) * amount).round()).clamp(0, 255),
    );
  }

  /// Затемнить цвет
  static Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 - amount)).round().clamp(0, 255),
      (color.green * (1 - amount)).round().clamp(0, 255),
      (color.blue * (1 - amount)).round().clamp(0, 255),
    );
  }
}
