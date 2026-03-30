import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:intl/intl.dart';

class PromocodeFormScreen extends StatefulWidget {
  final String businessId;
  final String businessSlug;
  final Map<String, dynamic>? promocode;

  const PromocodeFormScreen({
    super.key,
    required this.businessId,
    required this.businessSlug,
    this.promocode,
  });

  @override
  State<PromocodeFormScreen> createState() => _PromocodeFormScreenState();
}

class _PromocodeFormScreenState extends State<PromocodeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderAmountController = TextEditingController();
  final _maxDiscountAmountController = TextEditingController();
  final _maxUsesController = TextEditingController();
  final _maxUsesPerUserController = TextEditingController();

  String _discountType = 'percentage';
  bool _isActive = true;
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _hasValidPeriod = false;
  
  bool _isLoading = false;

  bool get isEditing => widget.promocode != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadPromocodeData();
    }
  }

  void _loadPromocodeData() {
    final promocode = widget.promocode!;
    _codeController.text = promocode['code'] ?? '';
    _descriptionController.text = promocode['description'] ?? '';
    _discountType = promocode['discount_type'] ?? 'percentage';
    _discountValueController.text = promocode['discount_value']?.toString() ?? '';
    _minOrderAmountController.text = promocode['min_order_amount']?.toString() ?? '';
    _maxDiscountAmountController.text = promocode['max_discount_amount']?.toString() ?? '';
    _maxUsesController.text = promocode['max_uses']?.toString() ?? '';
    _maxUsesPerUserController.text = promocode['max_uses_per_user']?.toString() ?? '';
    _isActive = promocode['is_active'] ?? true;
    
    if (promocode['valid_from'] != null) {
      _validFrom = DateTime.tryParse(promocode['valid_from']);
      _hasValidPeriod = true;
    }
    if (promocode['valid_until'] != null) {
      _validUntil = DateTime.tryParse(promocode['valid_until']);
      _hasValidPeriod = true;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _discountValueController.dispose();
    _minOrderAmountController.dispose();
    _maxDiscountAmountController.dispose();
    _maxUsesController.dispose();
    _maxUsesPerUserController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    bool isStartDate,
  ) async {
    final initialDate = isStartDate
        ? (_validFrom ?? DateTime.now())
        : (_validUntil ?? DateTime.now().add(const Duration(days: 30)));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null) {
        final dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartDate) {
            _validFrom = dateTime;
          } else {
            _validUntil = dateTime;
          }
          _hasValidPeriod = _validFrom != null || _validUntil != null;
        });
      }
    }
  }

  Future<void> _savePromocode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_hasValidPeriod && _validFrom != null && _validUntil != null) {
      if (_validUntil!.isBefore(_validFrom!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Дата окончания должна быть позже даты начала'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'code': _codeController.text.trim().toUpperCase(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'discount_type': _discountType,
        'discount_value': double.parse(_discountValueController.text),
        'min_order_amount': _minOrderAmountController.text.trim().isEmpty
            ? null
            : double.tryParse(_minOrderAmountController.text),
        'max_discount_amount': _maxDiscountAmountController.text.trim().isEmpty
            ? null
            : double.tryParse(_maxDiscountAmountController.text),
        'max_uses': _maxUsesController.text.trim().isEmpty
            ? null
            : int.tryParse(_maxUsesController.text),
        'max_uses_per_user': _maxUsesPerUserController.text.trim().isEmpty
            ? null
            : int.tryParse(_maxUsesPerUserController.text),
        'valid_from': _validFrom?.toIso8601String(),
        'valid_until': _validUntil?.toIso8601String(),
        'is_active': _isActive,
      };

      if (isEditing) {
        await _apiClient.dio.put(
          ApiConstants.promocode(widget.promocode!['id']),
          data: data,
        );
      } else {
        await _apiClient.dio.post(
          ApiConstants.createPromocode(widget.businessId),
          data: data,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Промокод обновлён' : 'Промокод создан'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось сохранить промокод. Попробуйте еще раз.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать промокод' : 'Создать промокод'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Код промокода *',
                hintText: 'SUMMER2024',
                helperText: 'Код будет автоматически преобразован в верхний регистр',
              ),
              textCapitalization: TextCapitalization.characters,
              enabled: !isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите код промокода';
                }
                if (value.trim().length < 3) {
                  return 'Код должен содержать минимум 3 символа';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Летняя скидка для новых клиентов',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _discountType,
              decoration: const InputDecoration(
                labelText: 'Тип скидки *',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'percentage',
                  child: Text('Процентная (%)'),
                ),
                DropdownMenuItem(
                  value: 'fixed',
                  child: Text('Фиксированная (₽)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _discountType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountValueController,
              decoration: InputDecoration(
                labelText: _discountType == 'percentage'
                    ? 'Размер скидки (%) *'
                    : 'Размер скидки (₽) *',
                hintText: _discountType == 'percentage' ? '10' : '100',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите размер скидки';
                }
                final numValue = double.tryParse(value);
                if (numValue == null) {
                  return 'Введите корректное число';
                }
                if (_discountType == 'percentage' && (numValue <= 0 || numValue > 100)) {
                  return 'Процент должен быть от 0 до 100';
                }
                if (_discountType == 'fixed' && numValue <= 0) {
                  return 'Сумма должна быть больше 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minOrderAmountController,
              decoration: const InputDecoration(
                labelText: 'Минимальная сумма заказа (₽)',
                hintText: '1000',
                helperText: 'Оставьте пустым, если ограничения нет',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            if (_discountType == 'percentage')
              TextFormField(
                controller: _maxDiscountAmountController,
                decoration: const InputDecoration(
                  labelText: 'Максимальная сумма скидки (₽)',
                  hintText: '500',
                  helperText: 'Ограничение максимальной суммы скидки',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            if (_discountType == 'percentage') const SizedBox(height: 16),
            TextFormField(
              controller: _maxUsesController,
              decoration: const InputDecoration(
                labelText: 'Максимум использований',
                hintText: '100',
                helperText: 'Общее количество использований промокода',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxUsesPerUserController,
              decoration: const InputDecoration(
                labelText: 'Максимум использований на пользователя',
                hintText: '1',
                helperText: 'Сколько раз один пользователь может использовать промокод',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Период действия'),
              subtitle: Text(_hasValidPeriod ? 'Установлен' : 'Без ограничений'),
              value: _hasValidPeriod,
              onChanged: (value) {
                setState(() {
                  _hasValidPeriod = value;
                  if (!value) {
                    _validFrom = null;
                    _validUntil = null;
                  }
                });
              },
            ),
            if (_hasValidPeriod) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Дата начала'),
                subtitle: Text(
                  _validFrom != null
                      ? DateFormat('dd.MM.yyyy HH:mm').format(_validFrom!)
                      : 'Не установлена',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              ListTile(
                title: const Text('Дата окончания'),
                subtitle: Text(
                  _validUntil != null
                      ? DateFormat('dd.MM.yyyy HH:mm').format(_validUntil!)
                      : 'Не установлена',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
            ],
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Активен'),
              subtitle: const Text('Промокод можно использовать'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _savePromocode,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Сохранить' : 'Создать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

