import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/presentation/bloc/orders/orders_bloc.dart';
import 'package:tg_store/mini_app/domain/entities/order.dart' as entities;

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {

  @override
  void initState() {
    super.initState();
    logger.i('OrderDetailScreen initState for orderId: ${widget.orderId}');
    
    // Загружаем детали заказа
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersBloc>().add(LoadOrderDetails(widget.orderId));
    });
  }

  @override
  Widget build(BuildContext context) {
    logger.i('OrderDetailScreen build for orderId: ${widget.orderId}');

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            String orderIdShort;
            if (state is OrdersLoaded && state.selectedOrder != null) {
              orderIdShort = state.selectedOrder!.id.substring(0, 8);
            } else if (state is OrdersLoaded && state.orders.isNotEmpty) {
              try {
                final order = state.orders.firstWhere(
                  (o) => o.id == widget.orderId,
                );
                orderIdShort = order.id.substring(0, 8);
              } catch (e) {
                orderIdShort = widget.orderId.substring(0, 8);
              }
            } else {
              orderIdShort = widget.orderId.substring(0, 8);
            }
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Детали заказа'),
                const SizedBox(width: 8),
                Text(
                  '#$orderIdShort',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ],
            );
          },
        ),
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            logger.d('OrderDetailScreen state: ${state.runtimeType}');

            if (state is OrdersLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is OrdersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Не удалось загрузить заказ. Попробуйте еще раз.'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<OrdersBloc>().add(LoadOrderDetails(widget.orderId));
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            if (state is OrdersLoaded && state.selectedOrder != null) {
              final order = state.selectedOrder!;
              return _buildOrderDetails(context, order);
            }

            // Если заказ не выбран, пытаемся найти его в списке
            if (state is OrdersLoaded) {
              final order = state.orders.firstWhere(
                (o) => o.id == widget.orderId,
                orElse: () => throw Exception('Order not found'),
              );
              return _buildOrderDetails(context, order);
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, entities.Order order) {
    final canCancel = order.status == entities.OrderStatus.new_ || 
                      order.status == entities.OrderStatus.accepted;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Кнопка отмены заказа (если можно отменить)
          if (canCancel) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelOrder(context, order),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Отменить заказ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Информация о заказе
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Заказ #${order.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Chip(
                        label: Text(_getStatusText(order.status)),
                        backgroundColor: _getStatusColor(order.status, context).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _getStatusColor(order.status, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Дата создания',
                    value: DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    icon: Icons.person,
                    label: 'Имя',
                    value: order.customerName,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    icon: Icons.phone,
                    label: 'Телефон',
                    value: order.customerPhone,
                  ),
                  if (order.customerAddress != null && order.customerAddress!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      icon: Icons.location_on,
                      label: 'Адрес',
                      value: order.customerAddress!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    icon: Icons.payment,
                    label: 'Способ оплаты',
                    value: order.paymentMethod == entities.PaymentMethod.online
                        ? 'Онлайн оплата'
                        : 'Наличными',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    icon: Icons.info,
                    label: 'Статус оплаты',
                    value: _getPaymentStatusText(order.paymentStatus),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Список товаров
          Text(
            'Товары',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ...order.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == order.items.length - 1;
                  
                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                          item.titleSnapshot,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} ₽',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: Text(
                          '${item.totalPrice.toStringAsFixed(0)} ₽',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      if (!isLast) const Divider(height: 1),
                    ],
                  );
                }),
                const Divider(height: 1, thickness: 2),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Стоимость доставки (если есть)
                      if (order.deliveryCost != null && order.deliveryCost! > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  order.deliveryMethod == 'delivery' ? 'Доставка' : 'Самовывоз',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                ),
                              ],
                            ),
                            Text(
                              '${order.deliveryCost!.toStringAsFixed(0)} ${order.currency}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Скидка (если есть)
                      if (order.discountAmount != null && order.discountAmount! > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Скидка:',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                            ),
                            Text(
                              '-${order.discountAmount!.toStringAsFixed(0)} ${order.currency}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Итоговая сумма
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Итого:',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${order.totalAmount.toStringAsFixed(0)} ${order.currency}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusText(dynamic status) {
    switch (status.toString()) {
      case 'OrderStatus.new_':
        return 'Новый';
      case 'OrderStatus.accepted':
        return 'Принят';
      case 'OrderStatus.preparing':
        return 'Готовится';
      case 'OrderStatus.ready':
        return 'Готов';
      case 'OrderStatus.cancelled':
        return 'Отменен';
      case 'OrderStatus.completed':
        return 'Завершен';
      default:
        return 'Неизвестно';
    }
  }

  Color _getStatusColor(dynamic status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toString()) {
      case 'OrderStatus.new_':
        return colorScheme.primary;
      case 'OrderStatus.accepted':
        return colorScheme.tertiary;
      case 'OrderStatus.preparing':
        return colorScheme.secondary;
      case 'OrderStatus.ready':
        return colorScheme.tertiary.withOpacity(0.7);
      case 'OrderStatus.cancelled':
        return colorScheme.error;
      case 'OrderStatus.completed':
        return colorScheme.onSurface.withOpacity(0.5);
      default:
        return colorScheme.onSurface.withOpacity(0.5);
    }
  }

  String _getPaymentStatusText(dynamic status) {
    switch (status.toString()) {
      case 'PaymentStatus.pending':
        return 'Ожидает оплаты';
      case 'PaymentStatus.paid':
        return 'Оплачен';
      case 'PaymentStatus.failed':
        return 'Ошибка оплаты';
      case 'PaymentStatus.refunded':
        return 'Возврат';
      default:
        return 'Неизвестно';
    }
  }

  Future<void> _cancelOrder(BuildContext context, entities.Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить заказ?'),
        content: Text(
          'Вы уверены, что хотите отменить заказ #${order.id.substring(0, 8)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Отменяем заказ
      context.read<OrdersBloc>().add(CancelOrder(order.id));

      // Ждем, пока заказ будет отменен
      await _waitForOrderCancellation(context, order.id);

      // Закрываем индикатор загрузки
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Показываем уведомление
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Заказ отменен'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }

      // Возвращаемся назад
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _waitForOrderCancellation(BuildContext context, String orderId) async {
    // Ждем максимум 10 секунд
    const maxWaitTime = Duration(seconds: 10);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final currentState = context.read<OrdersBloc>().state;
      if (currentState is OrdersLoaded) {
        final order = currentState.selectedOrder ?? 
          currentState.orders.firstWhere(
            (o) => o.id == orderId,
            orElse: () => throw Exception('Order not found'),
          );
        
        if (order.status == entities.OrderStatus.cancelled) {
          return;
        }
      }
    }
  }
}

