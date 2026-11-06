import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../models/order.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    required this.order,
    required this.history,
    super.key,
  });

  final Order order;
  final List<OrderStatusHistoryEntry> history;

  static const _deliveryStatuses = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];
  static const _pickupStatuses = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = order.isDelivery ? _deliveryStatuses : _pickupStatuses;
    final historyByStatus = {for (final entry in history) entry.status: entry};
    var latestProgress = order.status;
    if (order.status == OrderStatus.cancelled) {
      latestProgress = OrderStatus.pending;
      for (final entry in history) {
        if (entry.status != OrderStatus.cancelled) {
          latestProgress = entry.status;
        }
      }
    }
    final foundIndex = statuses.indexOf(latestProgress);
    final latestProgressIndex = foundIndex < 0 ? 0 : foundIndex;
    final visibleStatuses = order.status == OrderStatus.cancelled
        ? [...statuses.take(latestProgressIndex + 1), OrderStatus.cancelled]
        : statuses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.status == OrderStatus.cancelled) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            ),
            child: const Row(
              children: [
                Icon(Icons.cancel_outlined, color: AppColors.error),
                SizedBox(width: AppSpacing.smallMedium),
                Expanded(child: Text('This order was cancelled by the shop.')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        for (var index = 0; index < visibleStatuses.length; index++)
          _TimelineRow(
            status: visibleStatuses[index],
            entry: visibleStatuses[index] == OrderStatus.pending
                ? null
                : historyByStatus[visibleStatuses[index]],
            createdAt: order.date,
            isCurrent: visibleStatuses[index] == order.status,
            isComplete:
                visibleStatuses[index] == OrderStatus.pending ||
                historyByStatus.containsKey(visibleStatuses[index]),
            isLast: index == visibleStatuses.length - 1,
            textTheme: theme.textTheme,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.status,
    required this.entry,
    required this.createdAt,
    required this.isCurrent,
    required this.isComplete,
    required this.isLast,
    required this.textTheme,
  });

  final OrderStatus status;
  final OrderStatusHistoryEntry? entry;
  final DateTime createdAt;
  final bool isCurrent;
  final bool isComplete;
  final bool isLast;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == OrderStatus.cancelled;
    final color = isCancelled
        ? AppColors.error
        : isComplete
        ? AppColors.success
        : AppColors.border;
    final timestamp = status == OrderStatus.pending
        ? createdAt
        : entry?.changedAt;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Icon(
                isCancelled
                    ? Icons.cancel
                    : isComplete
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 20,
                color: color,
              ),
              if (!isLast) Container(width: 2, height: 28, color: color),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.smallMedium),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCancelled ? AppColors.error : null,
                  ),
                ),
                if (timestamp != null)
                  Text(
                    '${AppFormatters.date(timestamp)} · '
                    '${timestamp.hour.toString().padLeft(2, '0')}:'
                    '${timestamp.minute.toString().padLeft(2, '0')}'
                    '${status == OrderStatus.pending ? ' · Order placed' : ' · Updated by AquaQueue admin'}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
