import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/utils/logger.dart';

/// Виджет для автодополнения адресов с подсказками
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onAddressSelected; // Вызывается при выборе адреса
  final int? maxLines;
  final bool enabled;

  const AddressAutocompleteField({
    super.key,
    this.controller,
    this.labelText,
    this.prefixIcon,
    this.validator,
    this.onAddressSelected,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final ApiClient _apiClient = ApiClient();
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<Iterable<String>> _fetchSuggestions(String query) async {
    if (query.isEmpty || query.length < 2) {
      logger.d('Query too short: "$query" (length: ${query.length})');
      return [];
    }

    logger.d('Fetching address suggestions for query: "$query"');

    // Отменяем предыдущий запрос
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    try {
      final response = await _apiClient.dio.get(
        ApiConstants.suggestAddresses(),
        queryParameters: {
          'query': query,
          'limit': 5,
        },
        cancelToken: _cancelToken,
      );

      logger.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        logger.d('Response data type: ${data.runtimeType}');
        logger.d('Response data: $data');
        
        if (data is! Map) {
          logger.e('❌ Response data is not a Map! Type: ${data.runtimeType}');
          return [];
        }
        
        logger.d('Response data keys: ${data.keys}');
        
        if (!data.containsKey('suggestions')) {
          logger.e('❌ Response data missing "suggestions" key! Keys: ${data.keys}');
          return [];
        }
        
        final suggestionsList = data['suggestions'];
        logger.d('Suggestions list type: ${suggestionsList.runtimeType}');
        logger.d('Suggestions list: $suggestionsList');
        
        if (suggestionsList is! List) {
          logger.e('❌ Suggestions is not a List! Type: ${suggestionsList.runtimeType}');
          return [];
        }
        
        final suggestions = suggestionsList
            .map((s) {
              if (s is! Map) {
                logger.w('Suggestion item is not a Map: ${s.runtimeType}');
                return null;
              }
              final value = s['value'] as String?;
              logger.d('Suggestion value: $value');
              return value;
            })
            .whereType<String>()
            .toList();

        logger.i('✅ Fetched ${suggestions.length} address suggestions for query: "$query"');
        if (suggestions.isNotEmpty) {
          logger.d('Suggestions: ${suggestions.join(", ")}');
        } else {
          logger.w('⚠️ No suggestions found in response! Response: $data');
        }
        return suggestions;
      } else {
        logger.w('Address suggestions API returned status ${response.statusCode}');
        logger.d('Response data: ${response.data}');
        return [];
      }
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        logger.e('❌ Error fetching address suggestions', error: e);
        logger.d('Response status: ${e.response?.statusCode}');
        logger.d('Response data: ${e.response?.data}');
      } else {
        logger.d('Request cancelled');
      }
      return [];
    } catch (e) {
      logger.e('❌ Unexpected error fetching suggestions', error: e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Используем внутренний контроллер Autocomplete, но синхронизируем с внешним
        if (widget.controller != null) {
          // Инициализируем внутренний контроллер значением из внешнего
          if (textEditingController.text != widget.controller!.text) {
            textEditingController.text = widget.controller!.text;
          }
          
          // Синхронизируем изменения из внешнего контроллера во внутренний
          widget.controller!.addListener(() {
            if (textEditingController.text != widget.controller!.text) {
              textEditingController.text = widget.controller!.text;
            }
          });
          
          // Синхронизируем изменения из внутреннего контроллера во внешний
          textEditingController.addListener(() {
            if (widget.controller!.text != textEditingController.text) {
              widget.controller!.text = textEditingController.text;
            }
          });
        }

        return TextFormField(
          controller: textEditingController, // Всегда используем внутренний контроллер
          focusNode: focusNode,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: widget.labelText,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
            filled: false,
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
          ),
          validator: widget.validator,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final query = textEditingValue.text;
        logger.d('optionsBuilder called with query: "$query" (length: ${query.length})');
        
        if (query.isEmpty || query.length < 2) {
          logger.d('Query too short, returning empty');
          return const Iterable<String>.empty();
        }

        final suggestions = await _fetchSuggestions(query);
        logger.d('optionsBuilder returning ${suggestions.length} suggestions');
        return suggestions;
      },
      onSelected: (String selection) {
        // Обновляем controller
        if (widget.controller != null) {
          widget.controller!.text = selection;
        }
        
        // Вызываем callback при выборе адреса
        if (widget.onAddressSelected != null) {
          widget.onAddressSelected!(selection);
        }
      },
      displayStringForOption: (String option) => option,
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        final optionsList = options.toList();
        logger.d('optionsViewBuilder called with ${optionsList.length} options');
        
        if (optionsList.isEmpty) {
          logger.d('No options to display');
          return const SizedBox.shrink();
        }

        // Получаем размер экрана для правильного позиционирования
        final screenWidth = MediaQuery.of(context).size.width;
        final maxWidth = screenWidth - 32; // Учитываем padding
        
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: maxWidth > 400 ? 400 : maxWidth,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: optionsList.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
                itemBuilder: (context, index) {
                  final option = optionsList[index];
                  logger.d('Building option $index: $option');
                  return InkWell(
                    onTap: () {
                      logger.i('✅ Option tapped: $option');
                      onSelected(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
