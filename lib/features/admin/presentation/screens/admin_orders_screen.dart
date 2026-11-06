import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../models/order.dart';
import '../../models/admin_order.dart';
import '../admin_provider.dart';
import '../../../../shared/widgets/order_location_map.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isOrdersLoading && admin.orders.isEmpty) {
          return const AppLoadingIndicator.fullScreen(
            message: 'Loading customer orders...',
          );
        }
        if (admin.ordersError != null && admin.orders.isEmpty) {
          return AppErrorState(
            message: admin.ordersError!,
            onRetry: admin.retryOrders,
          );
        }
        final filtered = admin.filteredOrders;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                AppSpacing.small,
                AppSpacing.medium,
                0,
              ),
              child: TextField(
                onChanged: admin.setSearchQuery,
                decoration: const InputDecoration(
                  labelText: 'Search orders',
                  hintText: 'Order number or customer name',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              height: 58,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                children: [
                  _statusChip(context, admin, 'All', null),
                  for (final status in OrderStatus.values)
                    _statusChip(context, admin, status.label, status),
                ],
              ),
            ),
            if (admin.ordersError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                ),
                child: Text(
                  admin.ordersError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? AppEmptyState(
                      title: admin.orders.isEmpty
                          ? 'No orders yet'
                          : 'No matching orders',
                      message: admin.orders.isEmpty
                          ? 'Customer orders will appear here.'
                          : 'Try another search or status filter.',
                      icon: Icons.receipt_long_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: admin.refreshDashboard,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.small),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          return _AdminOrderCard(
                            entry: entry,
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => ChangeNotifierProvider.value(
                                value: admin,
                                child: _AdminOrderDetailsSheet(entry: entry),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _statusChip(
    BuildContext context,
    AdminProvider admin,
    String label,
    OrderStatus? status,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.small),
      child: ChoiceChip(
        label: Text(label),
        selected: admin.statusFilter == status,
        onSelected: (_) => admin.setStatusFilter(status),
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.entry, required this.onTap});

  final AdminOrder entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final order = entry.order;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.id,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _OrderStatusBadge(label: order.status.label),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                entry.customerName,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '${order.items.length} item(s) · '
                '${AppFormatters.date(order.date)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.small),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order.paymentStatus} · ${order.paymentMethod}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    AppFormatters.currency(order.total),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}

class _AdminOrderDetailsSheet extends StatelessWidget {
  const _AdminOrderDetailsSheet({required this.entry});

  final AdminOrder entry;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final currentEntry = admin.orders.cast<AdminOrder?>().firstWhere(
      (candidate) => candidate?.order.id == entry.order.id,
      orElse: () => null,
    );
    final orderEntry = currentEntry ?? entry;
    final order = orderEntry.order;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        children: [
          Text(order.id, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.medium),
          _DetailLine(label: 'Customer', value: orderEntry.customerName),
          _DetailLine(label: 'Email', value: orderEntry.customerEmail),
          _DetailLine(label: 'Phone', value: orderEntry.customerPhone),
          const Divider(),
          Text('Items', style: Theme.of(context).textTheme.titleLarge),
          for (final item in order.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.product.name),
              subtitle: Text('Quantity: ${item.quantity}'),
              trailing: Text(AppFormatters.currency(item.subtotal)),
            ),
          const Divider(),
          _DetailLine(
            label: 'Delivery type',
            value: order.isDelivery ? 'Home Delivery' : 'Pick Up',
          ),
          if (order.deliveryAddress != null)
            _DetailLine(label: 'Address', value: order.deliveryAddress!),
          if (order.isDelivery && order.deliveryLocation != null) ...[
            const SizedBox(height: AppSpacing.small),
            Text('Pinned delivery location'),
            const SizedBox(height: AppSpacing.small),
            OrderLocationMap(
              location: order.deliveryLocation!,
              showOpenInMaps: true,
            ),
          ],
          if (order.preferredDate != null)
            _DetailLine(label: 'Preferred date', value: order.preferredDate!),
          if (order.preferredTime != null)
            _DetailLine(label: 'Preferred time', value: order.preferredTime!),
          _DetailLine(label: 'Order status', value: order.status.label),
          _DetailLine(label: 'Payment method', value: order.paymentMethod),
          _DetailLine(label: 'Payment status', value: order.paymentStatus),
          _DetailLine(
            label: 'Subtotal',
            value: AppFormatters.currency(order.subtotal),
          ),
          _DetailLine(
            label: 'Delivery fee',
            value: AppFormatters.currency(order.deliveryFee),
          ),
          _DetailLine(
            label: 'Total',
            value: AppFormatters.currency(order.total),
          ),
          if (admin.actionError != null) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              admin.actionError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          for (final nextStatus in allowedNextStatuses(
            order.status,
            order.isDelivery
                ? OrderDeliveryType.delivery
                : OrderDeliveryType.pickup,
          ))
            FilledButton.icon(
              onPressed: admin.isActionInProgress
                  ? null
                  : () => _changeStatus(context, admin, order, nextStatus),
              icon: Icon(_statusIcon(nextStatus)),
              label: Text(_statusActionLabel(nextStatus)),
            ),
          if (order.paymentStatus == 'Unpaid')
            OutlinedButton.icon(
              onPressed: admin.isActionInProgress
                  ? null
                  : () => admin.confirmPayment(order.id),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Confirm payment received'),
            ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    AdminProvider admin,
    Order order,
    OrderStatus nextStatus,
  ) async {
    if (nextStatus == OrderStatus.cancelled ||
        nextStatus == OrderStatus.delivered) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            nextStatus == OrderStatus.cancelled
                ? 'Cancel this order?'
                : 'Mark this order as delivered?',
          ),
          content: Text(
            nextStatus == OrderStatus.cancelled
                ? 'This action is final and cannot be undone.'
                : 'Confirm that the customer has received this order.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Go back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                nextStatus == OrderStatus.cancelled
                    ? 'Cancel order'
                    : 'Mark delivered',
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await admin.updateOrderStatus(
      orderId: order.id,
      expectedStatus: order.status,
      nextStatus: nextStatus,
    );
  }

  String _statusActionLabel(OrderStatus status) => switch (status) {
    OrderStatus.confirmed => 'Confirm order',
    OrderStatus.preparing => 'Mark as Preparing',
    OrderStatus.outForDelivery => 'Mark as Out for Delivery',
    OrderStatus.delivered => 'Mark as Delivered',
    OrderStatus.cancelled => 'Cancel order',
    OrderStatus.pending => 'Mark as Pending',
  };

  IconData _statusIcon(OrderStatus status) => switch (status) {
    OrderStatus.confirmed => Icons.check_circle_outline,
    OrderStatus.preparing => Icons.inventory_2_outlined,
    OrderStatus.outForDelivery => Icons.local_shipping_outlined,
    OrderStatus.delivered => Icons.done_all,
    OrderStatus.cancelled => Icons.cancel_outlined,
    OrderStatus.pending => Icons.pending_outlined,
  };
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 124,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
