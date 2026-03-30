import 'package:flutter/material.dart';
import 'package:tg_store/core/constants/api_constants.dart';
import 'package:tg_store/core/network/api_client.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:tg_store/admin_panel/presentation/screens/promocode_form_screen.dart';

class PromocodesScreen extends StatefulWidget {
  final String businessSlug;

  const PromocodesScreen({
    super.key,
    required this.businessSlug,
  });

  @override
  State<PromocodesScreen> createState() => _PromocodesScreenState();
}

class _PromocodesScreenState extends State<PromocodesScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _promocodes = [];
  bool _isLoading = true;
  String? _error;
  String? _businessId;

  @override
  void initState() {
    super.initState();
    _loadBusinessId();
  }

  Future<void> _loadBusinessId() async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.businessBySlug(widget.businessSlug),
      );
      if (response.statusCode == 200) {
        setState(() {
          _businessId = response.data['id'];
        });
        _loadPromocodes();
      }
    } catch (e) {
      logger.e('Error loading business: $e');
      setState(() {
        _error = 'Не удалось загрузить информацию о бизнесе';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPromocodes() async {
    if (_businessId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.dio.get(
        ApiConstants.promocodes(_businessId!),
      );

      if (response.statusCode == 200) {
        setState(() {
          _promocodes = List<dynamic>.from(response.data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Неожиданный статус ответа: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить промокоды';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePromocode(String promocodeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить промокод?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiClient.dio.delete(
        ApiConstants.promocode(promocodeId),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Промокод удалён')),
        );
        _loadPromocodes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Не удалось удалить промокод. Попробуйте еще раз.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Промокоды'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPromocodes,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _businessId == null
          ? const Center(child: CircularProgressIndicator())
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPromocodes,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    )
                  : _promocodes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Промокодов пока нет',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _createPromocode,
                                child: const Text('Создать первый промокод'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPromocodes,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _promocodes.length,
                            itemBuilder: (context, index) {
                              final promocode = _promocodes[index];
                              return _buildPromocodeCard(promocode);
                            },
                          ),
                        ),
      floatingActionButton: _businessId != null
          ? FloatingActionButton(
              onPressed: _createPromocode,
              tooltip: 'Создать промокод',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildPromocodeCard(Map<String, dynamic> promocode) {
    final discountType = promocode['discount_type'] as String;
    final discountValue = promocode['discount_value'] as num;
    final isActive = promocode['is_active'] as bool? ?? false;
    final usesCount = promocode['uses_count'] as int? ?? 0;
    final maxUses = promocode['max_uses'];
    final validFrom = promocode['valid_from'] != null
        ? DateTime.tryParse(promocode['valid_from'])
        : null;
    final validUntil = promocode['valid_until'] != null
        ? DateTime.tryParse(promocode['valid_until'])
        : null;

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editPromocode(promocode),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      promocode['code'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isActive ? 'Активен' : 'Неактивен',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (promocode['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  promocode['description'] as String,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    discountType == 'percentage' ? Icons.percent : Icons.currency_ruble,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    discountType == 'percentage'
                        ? 'Скидка $discountValue%'
                        : 'Скидка ${discountValue.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (validFrom != null || validUntil != null) ...[
                Text(
                  'Период действия:',
                  style: TextStyle(
                    fontSize: 12, 
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  validFrom != null && validUntil != null
                      ? '${dateFormat.format(validFrom)} - ${dateFormat.format(validUntil)}'
                      : validFrom != null
                          ? 'С ${dateFormat.format(validFrom)}'
                          : 'До ${dateFormat.format(validUntil!)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Использовано: $usesCount${maxUses != null ? ' / $maxUses' : ''}',
                style: TextStyle(
                  fontSize: 12, 
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _editPromocode(promocode),
                    child: const Text('Редактировать'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _deletePromocode(promocode['id']),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createPromocode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromocodeFormScreen(
          businessId: _businessId!,
          businessSlug: widget.businessSlug,
        ),
      ),
    ).then((_) => _loadPromocodes());
  }

  void _editPromocode(Map<String, dynamic> promocode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromocodeFormScreen(
          businessId: _businessId!,
          businessSlug: widget.businessSlug,
          promocode: promocode,
        ),
      ),
    ).then((_) => _loadPromocodes());
  }
}

