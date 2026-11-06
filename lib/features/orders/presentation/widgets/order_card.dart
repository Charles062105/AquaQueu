import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../models/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, required this.onTap, super.key});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (order.status) {
      OrderStatus.pending => AppColors.warning,
      OrderStatus.confirmed || OrderStatus.preparing => AppColors.primary,
      OrderStatus.outForDelivery => AppColors.darkBlue,
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled => AppColors.error,
    };

    return Card(
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
                StatusChip(label: order.status.label, color: color),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              AppFormatters.date(order.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              order.productSummary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.xSmall,
              children: [
                Text(
                  AppFormatters.currency(order.total),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppColors.primary),
                ),
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('View details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
