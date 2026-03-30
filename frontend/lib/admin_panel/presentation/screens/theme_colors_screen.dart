import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tg_store/core/theme/business_theme.dart';

class ThemeColorsScreen extends StatefulWidget {
  final BusinessTheme? initialTheme;

  const ThemeColorsScreen({
    super.key,
    this.initialTheme,
  });

  @override
  State<ThemeColorsScreen> createState() => _ThemeColorsScreenState();
}

class _ThemeColorsScreenState extends State<ThemeColorsScreen> {
  late BusinessTheme _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.initialTheme ?? BusinessTheme.empty();
  }

  Future<void> _pickColor({
    required String title,
    required Color? currentColor,
    required Function(Color?) onColorSelected,
  }) async {
    Color? selectedColor = currentColor;
    
    final result = await showDialog<Color?>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        title: title,
        initialColor: selectedColor,
      ),
    );

    if (result != null) {
      onColorSelected(result);
    }
  }

  void _clearColor(Function(Color?) onColorSelected) {
    onColorSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка цветов темы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.of(context).pop(_theme);
            },
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Основные цвета',
            children: [
              _buildColorField(
                label: 'Основной цвет (Primary)',
                color: _theme.primaryColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                      primaryColor: color,
                      backgroundColor: _theme.backgroundColor,
                      textColor: _theme.textColor,
                      secondaryColor: _theme.secondaryColor,
                      tertiaryColor: _theme.tertiaryColor,
                      errorColor: _theme.errorColor,
                      surfaceColor: _theme.surfaceColor,
                      onPrimaryColor: _theme.onPrimaryColor,
                      onSecondaryColor: _theme.onSecondaryColor,
                      onTertiaryColor: _theme.onTertiaryColor,
                      onErrorColor: _theme.onErrorColor,
                      onSurfaceColor: _theme.onSurfaceColor,
                      primaryContainerColor: _theme.primaryContainerColor,
                      secondaryContainerColor: _theme.secondaryContainerColor,
                      tertiaryContainerColor: _theme.tertiaryContainerColor,
                      errorContainerColor: _theme.errorContainerColor,
                      onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                      onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                      onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                      onErrorContainerColor: _theme.onErrorContainerColor,
                      outlineColor: _theme.outlineColor,
                      outlineVariantColor: _theme.outlineVariantColor,
                    );
                  });
                },
                description: 'Основной цвет приложения (кнопки, акценты)',
              ),
              _buildColorField(
                label: 'Фоновый цвет (Background)',
                color: _theme.backgroundColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: color,
                    textColor: _theme.textColor,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: _theme.errorColor,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
                description: 'Цвет фона приложения',
              ),
              _buildColorField(
                label: 'Цвет текста (Text)',
                color: _theme.textColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: color,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: _theme.errorColor,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
                description: 'Основной цвет текста',
              ),
            ],
          ),
          _buildSection(
            title: 'Дополнительные цвета',
            children: [
              _buildColorField(
                label: 'Вторичный цвет (Secondary)',
                color: _theme.secondaryColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: _theme.textColor,
                    secondaryColor: color,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: _theme.errorColor,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
              ),
              _buildColorField(
                label: 'Третичный цвет (Tertiary)',
                color: _theme.tertiaryColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: _theme.textColor,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: color,
                    errorColor: _theme.errorColor,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
              ),
              _buildColorField(
                label: 'Цвет ошибки (Error)',
                color: _theme.errorColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: _theme.textColor,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: color,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
              ),
              _buildColorField(
                label: 'Цвет поверхности (Surface)',
                color: _theme.surfaceColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: _theme.textColor,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: _theme.errorColor,
                    surfaceColor: color,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Цвета контейнеров',
            children: [
              _buildColorField(
                label: 'Контейнер основного цвета',
                color: _theme.primaryContainerColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: _theme.textColor,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: _theme.errorColor,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: color,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
              ),
              _buildColorField(
                label: 'Текст на контейнере основного цвета',
                color: _theme.onPrimaryContainerColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: _theme.textColor,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: _theme.errorColor,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: color,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
              ),
              _buildColorField(
                label: 'Контейнер ошибки',
                color: _theme.errorContainerColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: _theme.textColor,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: _theme.errorColor,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: color,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
              ),
              _buildColorField(
                label: 'Текст на контейнере ошибки',
                color: _theme.onErrorContainerColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: _theme.textColor,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: _theme.errorColor,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: color,
                    outlineColor: _theme.outlineColor,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
              ),
            ],
          ),
          _buildSection(
            title: 'Цвета границ',
            children: [
              _buildColorField(
                label: 'Цвет границы (Outline)',
                color: _theme.outlineColor,
                onColorSelected: (color) {
                  if (!mounted) return;
                  setState(() {
                    _theme = BusinessTheme(
                    primaryColor: _theme.primaryColor,
                    backgroundColor: _theme.backgroundColor,
                    textColor: _theme.textColor,
                    secondaryColor: _theme.secondaryColor,
                    tertiaryColor: _theme.tertiaryColor,
                    errorColor: _theme.errorColor,
                    surfaceColor: _theme.surfaceColor,
                    onPrimaryColor: _theme.onPrimaryColor,
                    onSecondaryColor: _theme.onSecondaryColor,
                    onTertiaryColor: _theme.onTertiaryColor,
                    onErrorColor: _theme.onErrorColor,
                    onSurfaceColor: _theme.onSurfaceColor,
                    primaryContainerColor: _theme.primaryContainerColor,
                    secondaryContainerColor: _theme.secondaryContainerColor,
                    tertiaryContainerColor: _theme.tertiaryContainerColor,
                    errorContainerColor: _theme.errorContainerColor,
                    onPrimaryContainerColor: _theme.onPrimaryContainerColor,
                    onSecondaryContainerColor: _theme.onSecondaryContainerColor,
                    onTertiaryContainerColor: _theme.onTertiaryContainerColor,
                    onErrorContainerColor: _theme.onErrorContainerColor,
                    outlineColor: color,
                    outlineVariantColor: _theme.outlineVariantColor,
                  );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Информация',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Если оставить поле цвета пустым, будет использован цвет по умолчанию из темы приложения.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildColorField({
    required String label,
    required Color? color,
    required Function(Color?) onColorSelected,
    String? description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _pickColor(
              title: label,
              currentColor: color,
              onColorSelected: onColorSelected,
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color ?? Colors.transparent,
                border: Border.all(
                  color: color == null
                      ? Theme.of(context).colorScheme.outline
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: color == null
                  ? Icon(
                      Icons.color_lens_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: color != null
                ? () => _clearColor(onColorSelected)
                : null,
            tooltip: 'Очистить цвет',
          ),
        ],
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final String title;
  final Color? initialColor;

  const _ColorPickerDialog({
    required this.title,
    this.initialColor,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  Color? _selectedColor;
  late TextEditingController _hexController;
  bool _isCleared = false; // Флаг для отслеживания очистки цвета

  @override
  void initState() {
    super.initState();
    // Если начальный цвет null, используем дефолтный для отображения, но помним что он был null
    _selectedColor = widget.initialColor ?? Colors.blue;
    _isCleared = widget.initialColor == null;
    _hexController = TextEditingController(
      text: widget.initialColor != null
          ? '#${widget.initialColor!.value.toRadixString(16).substring(2).toUpperCase()}'
          : '',
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialColor = widget.initialColor;
    final displayColor = _selectedColor ?? Colors.blue; // Для отображения используем дефолтный если null
    final hasChanged = _isCleared 
        ? initialColor != null // Если очищено, то изменено только если был цвет
        : (initialColor != null && _selectedColor != null && _selectedColor!.value != initialColor.value);
    
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Показываем сравнение цветов
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: initialColor ?? Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: initialColor == null
                                        ? Theme.of(context).colorScheme.outline
                                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                    width: initialColor == null ? 2 : 1,
                                  ),
                                ),
                                child: initialColor == null
                                    ? Icon(
                                        Icons.color_lens_outlined,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        size: 32,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Текущий',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                initialColor != null
                                    ? '#${initialColor.value.toRadixString(16).substring(2).toUpperCase()}'
                                    : 'Не задан',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: initialColor != null ? 'monospace' : null,
                                  fontStyle: initialColor == null ? FontStyle.italic : null,
                                  color: initialColor == null
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 80,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _isCleared ? Colors.transparent : displayColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: hasChanged
                                        ? Theme.of(context).colorScheme.primary
                                        : (_isCleared 
                                            ? Theme.of(context).colorScheme.outline
                                            : Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                                    width: hasChanged ? 2 : (_isCleared ? 2 : 1),
                                  ),
                                ),
                                child: _isCleared
                                    ? Icon(
                                        Icons.color_lens_outlined,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                        size: 32,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Новый',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: hasChanged ? FontWeight.bold : FontWeight.normal,
                                  color: hasChanged
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                              Text(
                                _isCleared
                                    ? 'Не задан'
                                    : '#${displayColor.value.toRadixString(16).substring(2).toUpperCase()}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: _isCleared ? null : 'monospace',
                                  fontStyle: _isCleared ? FontStyle.italic : null,
                                  fontWeight: hasChanged ? FontWeight.bold : FontWeight.normal,
                                  color: _isCleared
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'HEX код',
                        hintText: '#RRGGBB',
                        prefixIcon: const Icon(Icons.color_lens),
                        helperText: 'Введите цвет в формате HEX (например: #FF5722)',
                      ),
                      controller: _hexController,
                      onChanged: (value) {
                        if (!mounted) return;
                        try {
                          String hex = value.replaceAll('#', '').trim();
                          if (hex.length == 6) {
                            final colorValue = int.parse('FF$hex', radix: 16);
                            final newColor = Color(colorValue);
                            if (_selectedColor == null || _selectedColor!.value != newColor.value) {
                              setState(() {
                                _selectedColor = newColor;
                                _isCleared = false;
                                _hexController.text = '#${newColor.value.toRadixString(16).substring(2).toUpperCase()}';
                              });
                            }
                          } else if (hex.isEmpty) {
                            // Если поле пустое, очищаем цвет (устанавливаем null)
                            setState(() {
                              _selectedColor = null;
                              _isCleared = true;
                            });
                          }
                        } catch (e) {
                          // Игнорируем ошибки парсинга
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      // Возвращаем null если цвет очищен, иначе возвращаем выбранный цвет
                      Navigator.of(context).pop(_isCleared ? null : _selectedColor);
                    },
                    child: const Text('Выбрать'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


