import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../models/order.dart';
import '../../../../services/order_service.dart';
import '../../../../shared/widgets/order_location_map.dart';
import '../widgets/order_status_timeline.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    required this.order,
    required this.orderService,
    super.key,
  });

  final Order order;
  final OrderService orderService;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Stream<Order> _orderStream;
  late Stream<List<OrderStatusHistoryEntry>> _historyStream;

  @override
  void initState() {
    super.initState();
    _createStreams();
  }

  void _createStreams() {
    _orderStream = widget.orderService.watchOrder(widget.order.id);
    _historyStream = widget.orderService.watchStatusHistory(widget.order.id);
  }

  void _retry() {
    setState(_createStreams);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: SafeArea(
        child: StreamBuilder<Order>(
          stream: _orderStream,
          initialData: widget.order,
          builder: (context, orderSnapshot) {
            if (orderSnapshot.hasError) {
              return AppErrorState(
                message:
                    'Your order could not be refreshed. Check your '
                    'connection and try again.',
                onRetry: _retry,
              );
            }
            final order = orderSnapshot.data;
            if (order == null) {
              return const AppLoadingIndicator.fullScreen(
                message: 'Loading order details...',
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.mediumLarge,
                AppSpacing.small,
                AppSpacing.mediumLarge,
                AppSpacing.large,
              ),
              children: [
                Text(order.id, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  AppFormatters.date(order.date),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Current status: ${order.status.label}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: order.status == OrderStatus.cancelled
                        ? AppColors.error
                        : AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                StreamBuilder<List<OrderStatusHistoryEntry>>(
                  stream: _historyStream,
                  initialData: const [],
                  builder: (context, historySnapshot) {
                    if (historySnapshot.hasError) {
                      return const Text(
                        'Status history is temporarily unavailable.',
                      );
                    }
                    return OrderStatusTimeline(
                      order: order,
                      history: historySnapshot.data ?? const [],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                Text('Items', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.smallMedium),
                for (final item in order.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.lightBlue,
                      child: Icon(
                        Icons.water_drop_outlined,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    title: Text(item.product.name),
                    subtitle: Text('Quantity: ${item.quantity}'),
                    trailing: Text(AppFormatters.currency(item.subtotal)),
                  ),
                const Divider(height: 28),
                _DetailRow(
                  label: 'Delivery type',
                  value: order.isDelivery
                      ? 'Home Delivery'
                      : 'Pick Up at Station',
                ),
                if (order.address != null)
                  _DetailRow(label: 'Delivery address', value: order.address!),
                if (order.isDelivery && order.deliveryLocation != null) ...[
                  const SizedBox(height: AppSpacing.small),
                  Text('Pinned location', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.small),
                  OrderLocationMap(location: order.deliveryLocation!),
                ],
                if (order.deliveryDate != null)
                  _DetailRow(
                    label: 'Preferred delivery date',
                    value: order.deliveryDate!,
                  ),
                if (order.deliveryTime != null)
                  _DetailRow(
                    label: 'Preferred delivery time',
                    value: order.deliveryTime!,
                  ),
                _DetailRow(label: 'Payment method', value: order.paymentMethod),
                _DetailRow(label: 'Payment status', value: order.paymentStatus),
                const Divider(height: 20),
                _DetailRow(
                  label: 'Subtotal',
                  value: AppFormatters.currency(order.subtotal),
                ),
                _DetailRow(
                  label: 'Delivery charge',
                  value: AppFormatters.currency(order.deliveryFee),
                ),
                _DetailRow(
                  label: 'Total amount',
                  value: AppFormatters.currency(order.total),
                  emphasized: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AppColors.darkBlue)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: AppSpacing.medium),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}
