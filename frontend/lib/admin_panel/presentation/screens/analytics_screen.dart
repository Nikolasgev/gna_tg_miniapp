import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tg_store/admin_panel/application/bloc/analytics/analytics_bloc.dart';

class AnalyticsScreen extends StatefulWidget {
  final String businessSlug;

  const AnalyticsScreen({
    super.key,
    required this.businessSlug,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // По умолчанию последние 30 дней
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    
    // Загружаем аналитику
    _loadAnalytics();
  }

  void _loadAnalytics() {
    context.read<AnalyticsBloc>().add(
          LoadAnalytics(
            businessSlug: widget.businessSlug,
            startDate: _startDate?.toIso8601String().split('T')[0],
            endDate: _endDate?.toIso8601String().split('T')[0],
          ),
        );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Выбрать период',
          ),
        ],
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AnalyticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки аналитики',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadAnalytics,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (state is AnalyticsLoaded) {
            final data = state.data;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Период
                  if (_startDate != null && _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Период: ${DateFormat('dd.MM.yyyy').format(_startDate!)} - ${DateFormat('dd.MM.yyyy').format(_endDate!)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Основные метрики
                  _buildMetricsGrid(context, data),
                  const SizedBox(height: 24),
                  
                  // График выручки
                  _buildRevenueChart(context, data),
                  const SizedBox(height: 24),
                  
                  // Статистика по статусам
                  _buildStatusStats(context, data),
                  const SizedBox(height: 24),
                  
                  // Топ товаров
                  _buildTopProducts(context, data),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> data) {
    final totalRevenue = (data['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = (data['total_orders'] as num?)?.toInt() ?? 0;
    final avgOrderValue = (data['avg_order_value'] as num?)?.toDouble() ?? 0.0;
    final totalDiscounts = (data['total_discounts'] as num?)?.toDouble() ?? 0.0;
    final promocodeUsage = (data['promocode_usage_count'] as num?)?.toInt() ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          context,
          title: 'Выручка',
          value: '${totalRevenue.toStringAsFixed(0)} ₽',
          icon: Icons.attach_money,
          color: Theme.of(context).colorScheme.primary,
        ),
        _buildMetricCard(
          context,
          title: 'Заказов',
          value: totalOrders.toString(),
          icon: Icons.shopping_cart,
          color: Theme.of(context).colorScheme.secondary,
        ),
        _buildMetricCard(
          context,
          title: 'Средний чек',
          value: '${avgOrderValue.toStringAsFixed(0)} ₽',
          icon: Icons.receipt,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        _buildMetricCard(
          context,
          title: 'Скидки',
          value: '${totalDiscounts.toStringAsFixed(0)} ₽',
          icon: Icons.discount,
          color: Theme.of(context).colorScheme.error,
        ),
        _buildMetricCard(
          context,
          title: 'Использовано промокодов',
          value: promocodeUsage.toString(),
          icon: Icons.local_offer,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, Map<String, dynamic> data) {
    var revenueByPeriod = (data['revenue_by_period'] as List<dynamic>?) ?? [];
    
    // Парсим реальные данные из API
    final chartData = <_ChartData>[];
    for (var item in revenueByPeriod) {
      final revenue = (item['revenue'] as num?)?.toDouble() ?? 0.0;
      final orders = (item['orders'] as num?)?.toInt() ?? 0;
      final dateStr = item['date'] as String? ?? '';
      
      String dateLabel = '';
      try {
        if (dateStr.isNotEmpty) {
          final date = DateTime.parse(dateStr);
          dateLabel = DateFormat('dd.MM').format(date);
        }
      } catch (e) {
        dateLabel = dateStr;
      }
      
      chartData.add(_ChartData(
        revenue: revenue,
        orders: orders,
        dateLabel: dateLabel,
      ));
    }

    // Если данных нет, используем моковые данные для демонстрации
    if (chartData.isEmpty) {
      final now = DateTime.now();
      final revenueValues = [1200.0, 1800.0, 2800.0, 2200.0, 1400.0, 2600.0, 2000.0];
      final ordersCount = [2, 4, 7, 5, 3, 6, 4];
      
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        chartData.add(_ChartData(
          revenue: revenueValues[i],
          orders: ordersCount[i],
          dateLabel: DateFormat('dd.MM').format(date),
        ));
      }
    }

    if (chartData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Нет данных за выбранный период',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
        ),
      );
    }

    final maxRevenue = chartData.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);
    // Используем цвет из темы приложения
    final barColor = Theme.of(context).colorScheme.primary;
    const maxBarHeight = 180.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выручка за последние 7 дней',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(chartData.length, (index) {
                  final data = chartData[index];
                  final heightRatio = data.revenue / maxRevenue;
                  final barHeight = (heightRatio * maxBarHeight).clamp(20.0, maxBarHeight);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: '${data.revenue.toStringAsFixed(0)} ₽\n${data.orders} заказ(ов)',
                            child: Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: barColor.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.dateLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStats(BuildContext context, Map<String, dynamic> data) {
    final ordersByStatus = (data['orders_by_status'] as Map<String, dynamic>?) ?? {};
    final ordersByPaymentStatus = (data['orders_by_payment_status'] as Map<String, dynamic>?) ?? {};

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'По статусу заказа',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...ordersByStatus.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getStatusLabel(entry.key),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            entry.value.toString(),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'По статусу оплаты',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...ordersByPaymentStatus.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getPaymentStatusLabel(entry.key),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          Text(
                            entry.value.toString(),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProducts(BuildContext context, Map<String, dynamic> data) {
    final topProducts = (data['top_products'] as List<dynamic>?) ?? [];

    if (topProducts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Нет данных о товарах',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Топ товаров',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            ...topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value as Map<String, dynamic>;
              final title = product['title'] as String? ?? '';
              final quantity = (product['quantity'] as num?)?.toInt() ?? 0;
              final revenue = (product['revenue'] as num?)?.toDouble() ?? 0.0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Продано: $quantity шт.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                trailing: Text(
                  '${revenue.toStringAsFixed(0)} ₽',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    const labels = {
      'new': 'Новые',
      'accepted': 'Принятые',
      'preparing': 'Готовятся',
      'ready': 'Готовы',
      'cancelled': 'Отменены',
      'completed': 'Завершены',
    };
    return labels[status] ?? status;
  }

  String _getPaymentStatusLabel(String status) {
    const labels = {
      'pending': 'Ожидает',
      'paid': 'Оплачено',
      'failed': 'Ошибка',
      'refunded': 'Возврат',
    };
    return labels[status] ?? status;
  }
}

class _ChartData {
  final double revenue;
  final int orders;
  final String dateLabel;

  _ChartData({
    required this.revenue,
    required this.orders,
    required this.dateLabel,
  });
}

