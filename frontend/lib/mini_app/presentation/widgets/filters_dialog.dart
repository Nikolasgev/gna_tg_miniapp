import 'package:flutter/material.dart';
import 'package:tg_store/core/utils/logger.dart' show logger;

class FiltersDialog extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final String? priceSort; // 'asc', 'desc', null

  const FiltersDialog({
    super.key,
    this.minPrice,
    this.maxPrice,
    this.priceSort,
  });

  @override
  State<FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<FiltersDialog> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  String? _priceSort;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: widget.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.maxPrice?.toString() ?? '',
    );
    _priceSort = widget.priceSort;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final minPriceText = _minPriceController.text.trim();
    final maxPriceText = _maxPriceController.text.trim();
    
    final minPrice = minPriceText.isEmpty
        ? null
        : double.tryParse(minPriceText);
    final maxPrice = maxPriceText.isEmpty
        ? null
        : double.tryParse(maxPriceText);

    // Валидация: minPrice не должен быть больше maxPrice
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Минимальная цена не может быть больше максимальной'),
        ),
      );
      return;
    }

    logger.d('🔍 FiltersDialog: Applying filters - minPrice=$minPrice, maxPrice=$maxPrice, priceSort=$_priceSort');
    
    Navigator.of(context).pop({
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'priceSort': _priceSort,
    });
  }

  void _clearFilters() {
    setState(() {
      _minPriceController.clear();
      _maxPriceController.clear();
      _priceSort = null;
    });
    
    // Применяем очистку фильтров сразу
    Navigator.of(context).pop({
      'minPrice': null,
      'maxPrice': null,
      'priceSort': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Фильтры',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Фильтр по цене
            const Text(
              'Цена',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'От',
                      hintText: '0',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'До',
                      hintText: '10000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Сортировка по цене
            const Text(
              'Сортировка по цене',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text('По возрастанию'),
              value: 'asc',
              groupValue: _priceSort,
              onChanged: (value) {
                setState(() {
                  _priceSort = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('По убыванию'),
              value: 'desc',
              groupValue: _priceSort,
              onChanged: (value) {
                setState(() {
                  _priceSort = value;
                });
              },
            ),
            RadioListTile<String?>(
              title: const Text('Без сортировки'),
              value: null,
              groupValue: _priceSort,
              onChanged: (value) {
                setState(() {
                  _priceSort = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Очистить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _applyFilters,
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

