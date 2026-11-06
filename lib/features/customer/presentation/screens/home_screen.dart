import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../models/app_user.dart';
import '../../../../models/order.dart';
import '../../../../models/product.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.products,
    required this.productsLoading,
    required this.productsError,
    required this.onRetryProducts,
    required this.orders,
    required this.ordersLoading,
    required this.ordersError,
    required this.onRetryOrders,
    required this.cart,
    required this.user,
    required this.onBrowseProducts,
    required this.onViewProduct,
    required this.onAddProduct,
    required this.onViewOrders,
    super.key,
  });

  final List<Product> products;
  final bool productsLoading;
  final String? productsError;
  final VoidCallback onRetryProducts;
  final List<Order> orders;
  final bool ordersLoading;
  final String? ordersError;
  final VoidCallback onRetryOrders;
  final Map<String, int> cart;
  final AppUser user;
  final VoidCallback onBrowseProducts;
  final ValueChanged<Product> onViewProduct;
  final ValueChanged<Product> onAddProduct;
  final VoidCallback onViewOrders;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = widget.orders.take(2).toList();
    final filteredProducts = widget.products.where((product) {
      final matchesQuery =
          product.name.toLowerCase().contains(_query.toLowerCase()) ||
          product.description.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory =
          _category == null ||
          product.name.toLowerCase().contains(_category!.toLowerCase()) ||
          product.categoryLabel.toLowerCase() == _category!.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.medium,
        AppSpacing.large,
      ),
      children: [
        Row(
          children: [
            const AppLogo(compact: true),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                'AquaQueue',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications.')),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'Good day, ${widget.user.fullName.split(' ').first} 👋',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          'Stay refreshed with your next refill.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.medium),
        TextField(
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: const InputDecoration(
            hintText: 'Search water products',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in [
                '5-Gallon',
                '1-Gallon',
                'Purified',
                'Mineral',
              ]) ...[
                _HomeCategoryChip(
                  label: category,
                  selected: _category == category,
                  onSelected: () => setState(
                    () => _category = _category == category ? null : category,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Container(
          padding: const EdgeInsets.all(AppSpacing.large),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clean Water,\nDelivered to You!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Quality water for your home, whenever you need it.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              FilledButton.tonalIcon(
                onPressed: widget.onBrowseProducts,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Browse water'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        Text('Quick services', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        Row(
          children: [
            Expanded(
              child: _ServiceShortcut(
                icon: Icons.water_drop_outlined,
                label: 'Water Refill',
                onTap: widget.onBrowseProducts,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: _ServiceShortcut(
                icon: Icons.delivery_dining_outlined,
                label: 'Home Delivery',
                onTap: widget.onBrowseProducts,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('My Orders'),
            subtitle: const Text('View your order history'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: widget.onViewOrders,
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        SectionHeader(
          title: 'Featured products',
          actionLabel: 'See all',
          onAction: widget.onBrowseProducts,
        ),
        const SizedBox(height: AppSpacing.small),
        if (widget.productsLoading)
          const Center(child: CircularProgressIndicator())
        else if (widget.productsError != null)
          TextButton.icon(
            onPressed: widget.onRetryProducts,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Could not load products. Tap to retry.'),
          )
        else if (filteredProducts.isEmpty)
          Text(
            'No products match your search.',
            style: theme.textTheme.bodyMedium,
          )
        else
          for (final product in filteredProducts.take(3)) ...[
            ProductCard(
              product: product,
              quantityInCart: widget.cart[product.id] ?? 0,
              onViewDetails: () => widget.onViewProduct(product),
              onAdd: () => widget.onAddProduct(product),
            ),
            const SizedBox(height: AppSpacing.small),
          ],
        const SizedBox(height: AppSpacing.small),
        SectionHeader(
          title: 'Recent orders',
          actionLabel: 'View all',
          onAction: widget.onViewOrders,
        ),
        const SizedBox(height: AppSpacing.small),
        if (widget.ordersLoading)
          const Center(child: CircularProgressIndicator())
        else if (widget.ordersError != null)
          TextButton.icon(
            onPressed: widget.onRetryOrders,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Could not load orders. Tap to retry.'),
          )
        else if (recent.isEmpty)
          const Text('Your recent orders will appear here.')
        else
          for (final order in recent) ...[
            _RecentOrderTile(order: order),
            const SizedBox(height: AppSpacing.small),
          ],
      ],
    );
  }
}

class _ServiceShortcut extends StatelessWidget {
  const _ServiceShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.medium,
          horizontal: AppSpacing.smallMedium,
        ),
        side: const BorderSide(color: AppColors.border),
        foregroundColor: AppColors.darkBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: AppColors.primaryBlue),
          const SizedBox(height: AppSpacing.small),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HomeCategoryChip extends StatelessWidget {
  const _HomeCategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    order.productSummary,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            StatusChip(label: order.status.label),
          ],
        ),
      ),
    );
  }
}
