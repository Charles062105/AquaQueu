import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../models/order_model.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    required this.orders,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onViewOrder,
    super.key,
  });

  final List<CustomerOrder> orders;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final ValueChanged<CustomerOrder> onViewOrder;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus? _status;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const AppLoadingIndicator.fullScreen(
        message: 'Loading your orders...',
      );
    }
    if (widget.errorMessage != null) {
      return AppErrorState(
        message: widget.errorMessage!,
        onRetry: widget.onRetry,
      );
    }
    final filtered = widget.orders
        .where((order) => _status == null || order.status == _status)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.large,
      ),
      children: [
        Text('My Orders', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          'Keep track of your water orders.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (widget.orders.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null),
                for (final status in OrderStatus.values)
                  _filterChip(status.label, status),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.medium),
        if (filtered.isEmpty)
          SizedBox(
            height: 384,
            child: AppEmptyState(
              title: _status == null
                  ? 'No orders yet'
                  : 'No ${_status!.label} orders',
              description: _status == null
                  ? 'Your order history will appear here after you place an order.'
                  : 'Try another status filter to see your orders.',
              icon: Icons.receipt_long_outlined,
            ),
          )
        else
          for (final order in filtered) ...[
            OrderCard(order: order, onTap: () => widget.onViewOrder(order)),
            const SizedBox(height: AppSpacing.small),
          ],
      ],
    );
  }

  Widget _filterChip(String label, OrderStatus? status) {
    final selected = _status == status;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.small),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _status = status),
        selectedColor: AppColors.lightBlue,
        side: BorderSide(
          color: selected ? AppColors.primaryBlue : AppColors.border,
        ),
      ),
    );
  }
}
