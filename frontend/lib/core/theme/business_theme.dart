import 'package:flutter/material.dart';

/// Модель темы бизнеса, загружаемая с бекенда
class BusinessTheme {
  // Основные цвета
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? textColor;
  
  // Дополнительные цвета темы
  final Color? secondaryColor;
  final Color? tertiaryColor;
  final Color? errorColor;
  final Color? surfaceColor;
  final Color? onPrimaryColor;
  final Color? onSecondaryColor;
  final Color? onTertiaryColor;
  final Color? onErrorColor;
  final Color? onSurfaceColor;
  final Color? primaryContainerColor;
  final Color? secondaryContainerColor;
  final Color? tertiaryContainerColor;
  final Color? errorContainerColor;
  final Color? onPrimaryContainerColor;
  final Color? onSecondaryContainerColor;
  final Color? onTertiaryContainerColor;
  final Color? onErrorContainerColor;
  final Color? outlineColor;
  final Color? outlineVariantColor;

  const BusinessTheme({
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.secondaryColor,
    this.tertiaryColor,
    this.errorColor,
    this.surfaceColor,
    this.onPrimaryColor,
    this.onSecondaryColor,
    this.onTertiaryColor,
    this.onErrorColor,
    this.onSurfaceColor,
    this.primaryContainerColor,
    this.secondaryContainerColor,
    this.tertiaryContainerColor,
    this.errorContainerColor,
    this.onPrimaryContainerColor,
    this.onSecondaryContainerColor,
    this.onTertiaryContainerColor,
    this.onErrorContainerColor,
    this.outlineColor,
    this.outlineVariantColor,
  });

  /// Создать из hex строки (#RRGGBB или #AARRGGBB)
  static Color? _colorFromHex(String? hexString) {
    if (hexString == null || hexString.isEmpty || hexString.trim().isEmpty) {
      return null;
    }

    // Убираем # если есть
    String hex = hexString.replaceAll('#', '').trim();

    // Добавляем FF для альфа-канала, если его нет
    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Преобразовать Color в hex строку
  static String? _colorToHex(Color? color) {
    if (color == null) return null;
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Создать BusinessTheme из JSON
  factory BusinessTheme.fromJson(Map<String, dynamic> json) {
    return BusinessTheme(
      primaryColor: _colorFromHex(json['primary_color'] as String?),
      backgroundColor: _colorFromHex(json['background_color'] as String?),
      textColor: _colorFromHex(json['text_color'] as String?),
      secondaryColor: _colorFromHex(json['secondary_color'] as String?),
      tertiaryColor: _colorFromHex(json['tertiary_color'] as String?),
      errorColor: _colorFromHex(json['error_color'] as String?),
      surfaceColor: _colorFromHex(json['surface_color'] as String?),
      onPrimaryColor: _colorFromHex(json['on_primary_color'] as String?),
      onSecondaryColor: _colorFromHex(json['on_secondary_color'] as String?),
      onTertiaryColor: _colorFromHex(json['on_tertiary_color'] as String?),
      onErrorColor: _colorFromHex(json['on_error_color'] as String?),
      onSurfaceColor: _colorFromHex(json['on_surface_color'] as String?),
      primaryContainerColor: _colorFromHex(json['primary_container_color'] as String?),
      secondaryContainerColor: _colorFromHex(json['secondary_container_color'] as String?),
      tertiaryContainerColor: _colorFromHex(json['tertiary_container_color'] as String?),
      errorContainerColor: _colorFromHex(json['error_container_color'] as String?),
      onPrimaryContainerColor: _colorFromHex(json['on_primary_container_color'] as String?),
      onSecondaryContainerColor: _colorFromHex(json['on_secondary_container_color'] as String?),
      onTertiaryContainerColor: _colorFromHex(json['on_tertiary_container_color'] as String?),
      onErrorContainerColor: _colorFromHex(json['on_error_container_color'] as String?),
      outlineColor: _colorFromHex(json['outline_color'] as String?),
      outlineVariantColor: _colorFromHex(json['outline_variant_color'] as String?),
    );
  }

  /// Преобразовать в JSON для отправки на бэкенд
  Map<String, dynamic> toJson() {
    return {
      'primary_color': _colorToHex(primaryColor),
      'background_color': _colorToHex(backgroundColor),
      'text_color': _colorToHex(textColor),
      'secondary_color': _colorToHex(secondaryColor),
      'tertiary_color': _colorToHex(tertiaryColor),
      'error_color': _colorToHex(errorColor),
      'surface_color': _colorToHex(surfaceColor),
      'on_primary_color': _colorToHex(onPrimaryColor),
      'on_secondary_color': _colorToHex(onSecondaryColor),
      'on_tertiary_color': _colorToHex(onTertiaryColor),
      'on_error_color': _colorToHex(onErrorColor),
      'on_surface_color': _colorToHex(onSurfaceColor),
      'primary_container_color': _colorToHex(primaryContainerColor),
      'secondary_container_color': _colorToHex(secondaryContainerColor),
      'tertiary_container_color': _colorToHex(tertiaryContainerColor),
      'error_container_color': _colorToHex(errorContainerColor),
      'on_primary_container_color': _colorToHex(onPrimaryContainerColor),
      'on_secondary_container_color': _colorToHex(onSecondaryContainerColor),
      'on_tertiary_container_color': _colorToHex(onTertiaryContainerColor),
      'on_error_container_color': _colorToHex(onErrorContainerColor),
      'outline_color': _colorToHex(outlineColor),
      'outline_variant_color': _colorToHex(outlineVariantColor),
    };
  }

  /// Создать пустую тему (без кастомных цветов)
  factory BusinessTheme.empty() {
    return const BusinessTheme();
  }

  /// Проверить, есть ли кастомные цвета
  bool get hasCustomColors =>
      primaryColor != null ||
      backgroundColor != null ||
      textColor != null ||
      secondaryColor != null ||
      tertiaryColor != null ||
      errorColor != null ||
      surfaceColor != null ||
      onPrimaryColor != null ||
      onSecondaryColor != null ||
      onTertiaryColor != null ||
      onErrorColor != null ||
      onSurfaceColor != null ||
      primaryContainerColor != null ||
      secondaryContainerColor != null ||
      tertiaryContainerColor != null ||
      errorContainerColor != null ||
      onPrimaryContainerColor != null ||
      onSecondaryContainerColor != null ||
      onTertiaryContainerColor != null ||
      onErrorContainerColor != null ||
      outlineColor != null ||
      outlineVariantColor != null;
}





