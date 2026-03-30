import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tg_store/admin_panel/application/bloc/orders/orders_bloc.dart';
import 'package:tg_store/admin_panel/data/repositories/orders_repository_impl.dart';

class OrdersScreen extends StatefulWidget {
  final String businessSlug;

  const OrdersScreen({
    super.key,
    required this.businessSlug,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;
  String? _filterStatus; // null = все, или конкретный статус
  String? _filterPaymentStatus; // null = все, или конкретный статус оплаты
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> allOrders) {
    var orders = List<Map<String, dynamic>>.from(allOrders);
    
    // Поиск по имени клиента, телефону или ID заказа
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      orders = orders.where((order) {
        final customerName = (order['customer_name'] as String? ?? '').toLowerCase();
        final customerPhone = (order['customer_phone'] as String? ?? '').toLowerCase();
        final orderId = (order['id'] as String? ?? '').toLowerCase();
        return customerName.contains(query) || 
               customerPhone.contains(query) || 
               orderId.contains(query);
      }).toList();
    }
    
    // Фильтр по статусу
    if (_filterStatus != null) {
      orders = orders.where((order) => order['status'] == _filterStatus).toList();
    }
    
    // Фильтр по статусу оплаты
    if (_filterPaymentStatus != null) {
      orders = orders.where((order) => order['payment_status'] == _filterPaymentStatus).toList();
    }
    
    return orders;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.isEmpty ? null : value;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = null;
    });
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _filterStatus = status;
    });
  }

  void _onPaymentStatusFilterChanged(String? paymentStatus) {
    setState(() {
      _filterPaymentStatus = paymentStatus;
    });
  }

  void _updateOrderStatus(BuildContext context, String orderId, String? status, String? paymentStatus) {
    context.read<OrdersBloc>().add(
      UpdateOrderStatus(
        widget.businessSlug,
        orderId,
        status ?? '',
        paymentStatus: paymentStatus,
      ),
    );
  }

  Future<void> _showStatusDialog(BuildContext context, String orderId, String currentStatus) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить статус заказа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(context, 'new', 'Новый', currentStatus),
            _buildStatusOption(context, 'accepted', 'Принят', currentStatus),
            _buildStatusOption(context, 'preparing', 'Готовится', currentStatus),
            _buildStatusOption(context, 'ready', 'Готов', currentStatus),
            _buildStatusOption(context, 'cancelled', 'Отменен', currentStatus),
            _buildStatusOption(context, 'completed', 'Завершен', currentStatus),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      _updateOrderStatus(context, orderId, newStatus, null);
    }
  }

  Future<void> _showPaymentStatusDialog(BuildContext context, String orderId, String currentPaymentStatus) async {
    final newPaymentStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить статус оплаты'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption(context, 'pending', 'Ожидает оплаты', currentPaymentStatus),
            _buildStatusOption(context, 'paid', 'Оплачен', currentPaymentStatus),
            _buildStatusOption(context, 'failed', 'Ошибка оплаты', currentPaymentStatus),
            _buildStatusOption(context, 'refunded', 'Возврат', currentPaymentStatus),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (newPaymentStatus != null && newPaymentStatus != currentPaymentStatus) {
      _updateOrderStatus(context, orderId, null, newPaymentStatus);
    }
  }

  Widget _buildStatusOption(BuildContext context, String value, String label, String currentValue) {
    final isSelected = value == currentValue;
    return ListTile(
      title: Text(label),
      leading: Radio<String>(
        value: value,
        groupValue: currentValue,
        onChanged: (selectedValue) {
          Navigator.pop(context, selectedValue);
        },
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context, value);
      },
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'Новый';
      case 'accepted':
        return 'Принят';
      case 'preparing':
        return 'Готовится';
      case 'ready':
        return 'Готов';
      case 'cancelled':
        return 'Отменен';
      case 'completed':
        return 'Завершен';
      default:
        return status;
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'new':
        return colorScheme.primary;
      case 'accepted':
        return colorScheme.tertiary;
      case 'preparing':
        return colorScheme.secondary;
      case 'ready':
        return colorScheme.primary;
      case 'cancelled':
        return colorScheme.error;
      case 'completed':
        return colorScheme.onSurface.withOpacity(0.5);
      default:
        return colorScheme.onSurface.withOpacity(0.5);
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Ожидает оплаты';
      case 'paid':
        return 'Оплачен';
      case 'failed':
        return 'Ошибка оплаты';
      case 'refunded':
        return 'Возврат';
      default:
        return status;
    }
  }

  Color _getPaymentStatusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'pending':
        return colorScheme.tertiary;
      case 'paid':
        return colorScheme.primary;
      case 'failed':
        return colorScheme.error;
      case 'refunded':
        return colorScheme.secondary;
      default:
        return colorScheme.onSurface.withOpacity(0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersBloc(
        ordersRepository: OrdersRepositoryImpl(),
      )..add(LoadOrders(widget.businessSlug, limit: 50)),
      child: BlocListener<OrdersBloc, OrdersState>(
        listener: (context, state) {
          if (state is OrderUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Статус обновлен'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            context.read<OrdersBloc>().add(LoadOrders(widget.businessSlug, limit: 50));
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            List<Map<String, dynamic>> allOrders = [];
            bool isLoading = false;
            String? error;

            if (state is OrdersLoading) {
              isLoading = true;
            } else if (state is OrdersLoaded) {
              allOrders = state.orders.cast<Map<String, dynamic>>();
            } else if (state is OrdersError) {
              error = state.message;
            }

            final filteredOrders = _applyFilters(allOrders);

            return Scaffold(
              appBar: AppBar(
                title: const Text('Заказы'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(120),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Поиск
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Поиск по имени, телефону или ID заказа',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            _searchDebounce?.cancel();
                            _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                              if (mounted && _searchController.text == value) {
                                _onSearchChanged(value);
                              }
                            });
                          },
                        ),
                      ),
                      // Фильтры
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _filterStatus,
                                decoration: InputDecoration(
                                  labelText: 'Статус заказа',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Все статусы'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'new',
                                    child: Text('Новый'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'accepted',
                                    child: Text('Принят'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'preparing',
                                    child: Text('Готовится'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'ready',
                                    child: Text('Готов'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'cancelled',
                                    child: Text('Отменен'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'completed',
                                    child: Text('Завершен'),
                                  ),
                                ],
                                onChanged: (value) => _onStatusFilterChanged(value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _filterPaymentStatus,
                                decoration: InputDecoration(
                                  labelText: 'Статус оплаты',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                                items: const [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Все оплаты'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'pending',
                                    child: Text('Ожидает оплаты'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'paid',
                                    child: Text('Оплачен'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'failed',
                                    child: Text('Ошибка оплаты'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'refunded',
                                    child: Text('Возврат'),
                                  ),
                                ],
                                onChanged: (value) => _onPaymentStatusFilterChanged(value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              body: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Не удалось загрузить заказы. Попробуйте еще раз.'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<OrdersBloc>().add(LoadOrders(widget.businessSlug, limit: 50));
                                },
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      : filteredOrders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined, 
                                    size: 64, 
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Нет заказов'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Заказы будут отображаться здесь',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                context.read<OrdersBloc>().add(LoadOrders(widget.businessSlug, limit: 50));
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = filteredOrders[index];
                          final createdAt = DateTime.parse(order['created_at'] as String);
                          final items = order['items'] as List? ?? [];
                          final orderId = order['id'] as String;
                          final currentStatus = order['status'] as String;
                          final currentPaymentStatus = order['payment_status'] as String;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              childrenPadding: const EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(context, currentStatus),
                                child: Text(
                                  '#${orderId.substring(0, 6)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                'Заказ #${orderId.substring(0, 8)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    order['customer_name'] as String? ?? 'Без имени',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd.MM.yyyy HH:mm').format(createdAt),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order['total_amount']} ${order['currency'] ?? 'RUB'}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Кнопки для изменения статусов - перемещены в subtitle
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 200),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: InkWell(
                                            onTap: () => _showStatusDialog(context, orderId, currentStatus),
                                            child: Chip(
                                              label: Text(
                                                _getStatusText(currentStatus),
                                                style: const TextStyle(fontSize: 10),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              backgroundColor: _getStatusColor(context, currentStatus).withOpacity(0.2),
                                              labelStyle: TextStyle(
                                                color: _getStatusColor(context, currentStatus),
                                                fontSize: 10,
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: InkWell(
                                            onTap: () => _showPaymentStatusDialog(context, orderId, currentPaymentStatus),
                                            child: Chip(
                                              label: Text(
                                                _getPaymentStatusText(currentPaymentStatus),
                                                style: const TextStyle(fontSize: 10),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              backgroundColor: _getPaymentStatusColor(context, currentPaymentStatus).withOpacity(0.2),
                                              labelStyle: TextStyle(
                                                color: _getPaymentStatusColor(context, currentPaymentStatus),
                                                fontSize: 10,
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (order['customer_phone'] != null) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(order['customer_phone'] as String),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (order['customer_address'] != null) ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.location_on, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(order['customer_address'] as String),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Row(
                                      children: [
                                        const Icon(Icons.payment, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          order['payment_method'] == 'online'
                                              ? 'Онлайн оплата'
                                              : 'Наличными',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Товары:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 12),
                                    ...items.map<Widget>((item) {
                                      final itemMetadata = item['item_metadata'] as Map<String, dynamic>?;
                                      final selectedVariations = itemMetadata?['selected_variations'] as Map<String, dynamic>?;
                                      final note = itemMetadata?['note'] as String?;
                                      final categoryNames = itemMetadata?['category_names'] as List<dynamic>?;
                                      final categorySurcharges = itemMetadata?['category_surcharges'] as Map<String, dynamic>?;
                                      
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Название и цена
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item['title_snapshot'] as String? ?? 'Без названия',
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${item['quantity']} × ${item['unit_price']} = ${item['total_price']} ${order['currency'] ?? 'RUB'}',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                    textAlign: TextAlign.end,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Количество
                                              Text(
                                                'Количество: ${item['quantity']}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                              // Вариации
                                              if (selectedVariations != null && selectedVariations.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Выбранные опции:',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                ),
                                                ...selectedVariations.entries.map((entry) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                                                    child: Text(
                                                      '${entry.key}: ${entry.value}',
                                                      style: Theme.of(context).textTheme.bodySmall,
                                                    ),
                                                  );
                                                }),
                                              ],
                                              // Категории
                                              if (categoryNames != null && categoryNames.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Категории: ${categoryNames.join(", ")}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              ],
                                              // Доплаты за категории
                                              if (categorySurcharges != null && categorySurcharges.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Доплаты:',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                ),
                                                ...categorySurcharges.entries.map((entry) {
                                                  if (entry.value > 0) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                                                      child: Text(
                                                        '${entry.key}: +${entry.value} ${order['currency'] ?? 'RUB'}',
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              color: Theme.of(context).colorScheme.primary,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                  return const SizedBox.shrink();
                                                }),
                                              ],
                                              // Заметка
                                              if (note != null && note.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.all(8.0),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primaryContainer,
                                                    borderRadius: BorderRadius.circular(4.0),
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Icon(
                                                        Icons.note, 
                                                        size: 16, 
                                                        color: Theme.of(context).colorScheme.primary,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          note,
                                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 8),
                                    // Информация о доставке
                                    if (order['order_metadata'] != null) ...[
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Доставка:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      Builder(
                                        builder: (context) {
                                          final metadata = order['order_metadata'] as Map<String, dynamic>?;
                                          final deliveryMethod = metadata?['delivery_method'] as String?;
                                          final deliveryCost = metadata?['delivery_cost'] as num?;
                                          
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Способ: ${deliveryMethod == 'delivery' ? 'Доставка' : 'Самовывоз'}',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                              if (deliveryCost != null && deliveryCost > 0) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Стоимость доставки: $deliveryCost ${order['currency'] ?? 'RUB'}',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: Theme.of(context).colorScheme.primary,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                    // Итоговая сумма
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Итого:',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        Text(
                                          '${order['total_amount']} ${order['currency'] ?? 'RUB'}',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
