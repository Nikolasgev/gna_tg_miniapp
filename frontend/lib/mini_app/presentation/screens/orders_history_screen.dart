import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/presentation/bloc/orders/orders_bloc.dart';
import 'package:tg_store/mini_app/presentation/navigation/app_router.dart';
import 'package:tg_store/mini_app/application/bloc/auth/auth_bloc.dart';
import 'package:tg_store/mini_app/presentation/screens/order_detail_screen.dart';
import 'package:tg_store/l10n/app_localizations.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    logger.i('OrdersHistoryScreen initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Загружаем заказы при первом появлении экрана и при возврате на него
    if (!_hasLoaded) {
      logger.i('OrdersHistoryScreen didChangeDependencies - loading orders (first time)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadOrders();
          _hasLoaded = true;
        }
      });
    }
  }

  @override
  void didUpdateWidget(OrdersHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем заказы при обновлении виджета (например, при возврате на экран)
    logger.i('OrdersHistoryScreen didUpdateWidget - reloading orders');
    _loadOrders();
  }

  void _loadOrders() {
    final authState = context.read<AuthBloc>().state;
    int? telegramId;
    if (authState is AuthAuthenticated) {
      telegramId = authState.user.id;
      logger.i('Loading orders for telegramId: $telegramId');
    } else {
      // TODO: Для тестирования без Telegram нужно добавить возможность мокирования Telegram ID
      // Можно использовать SharedPreferences или константу для разработки
      // В production это должно показывать ошибку или требовать авторизацию
      telegramId = 123456789; // Мок ID для тестов
      logger.w('Auth not authenticated, using mock telegramId: $telegramId');
    }
    context.read<OrdersBloc>().add(LoadOrders(telegramId: telegramId));
  }

  @override
  Widget build(BuildContext context) {
    logger.i('OrdersHistoryScreen build');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.ordersHistory),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          logger.d('OrdersHistoryScreen state: ${state.runtimeType}');
          
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
                    AppLocalizations.of(context)!.loadingError,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Не удалось загрузить заказы. Попробуйте еще раз.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          if (state is OrdersLoaded) {
            final orders = state.orders;
            
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noOrders,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.ordersWillAppearHere,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        AppRouter.toCatalog();
                      },
                      child: Text(AppLocalizations.of(context)!.goToCatalog),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadOrders();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('Заказ #${order.id.substring(0, 8)}'),
                      subtitle: Text(
                        '${DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt)} • ${order.totalAmount.toStringAsFixed(0)} ₽',
                      ),
                      trailing: Chip(
                        label: Text(_getStatusText(order.status)),
                        backgroundColor: _getStatusColor(order.status, context).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _getStatusColor(order.status, context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(orderId: order.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  String _getStatusText(dynamic status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toString()) {
      case 'OrderStatus.new_':
        return l10n.statusNew;
      case 'OrderStatus.accepted':
        return l10n.statusAccepted;
      case 'OrderStatus.preparing':
        return l10n.statusPreparing;
      case 'OrderStatus.ready':
        return l10n.statusReady;
      case 'OrderStatus.cancelled':
        return l10n.statusCancelled;
      case 'OrderStatus.completed':
        return l10n.statusCompleted;
      default:
        return l10n.unknown;
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

}

