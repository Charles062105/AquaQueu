import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/quantity_selector.dart';
import '../../../../features/products/models/product_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    required this.product,
    required this.onAddToCart,
    required this.onCheckout,
    super.key,
  });

  final Product product;
  final ValueChanged<int> onAddToCart;
  final VoidCallback onCheckout;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = widget.product.price * _quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.mediumLarge),
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(
                  AppSpacing.radiusExtraLarge,
                ),
              ),
              child: Icon(
                Icons.water_drop_rounded,
                size: 96,
                color: widget.product.category == ProductCategory.mineral
                    ? AppColors.darkBlue
                    : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(widget.product.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.small),
            Text(widget.product.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.smallMedium),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  '₱${widget.product.price}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Icon(
                  widget.product.available
                      ? Icons.check_circle
                      : Icons.remove_circle_outline,
                  color: widget.product.available
                      ? AppColors.success
                      : AppColors.error,
                  size: 18,
                ),
                Text(
                  widget.product.available ? 'Available' : 'Unavailable',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.product.available
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text('Quantity', style: theme.textTheme.titleMedium),
                  ),
                  QuantitySelector(
                    quantity: _quantity,
                    onChanged: (value) => setState(() => _quantity = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.smallMedium),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text('Subtotal', style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    '₱$subtotal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            AppButton(
              label: 'Add to Cart',
              onPressed: widget.product.available
                  ? () {
                      widget.onAddToCart(_quantity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${widget.product.name} added to cart.',
                          ),
                          action: SnackBarAction(
                            label: 'Checkout',
                            onPressed: widget.onCheckout,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.smallMedium),
            AppButton(
              label: 'Continue to Checkout',
              type: AppButtonType.secondary,
              onPressed: widget.product.available
                  ? () {
                      widget.onAddToCart(_quantity);
                      widget.onCheckout();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
