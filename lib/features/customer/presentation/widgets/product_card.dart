import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../products/models/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onViewDetails,
    required this.onAdd,
    this.quantityInCart = 0,
    super.key,
  });

  final Product product;
  final VoidCallback onViewDetails;
  final VoidCallback onAdd;
  final int quantityInCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        excludeFromSemantics: true,
        onTap: onViewDetails,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.small + AppSpacing.xSmall),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  size: 38,
                  color: product.category == ProductCategory.mineral
                      ? AppColors.darkBlue
                      : AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.small + AppSpacing.xSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xSmall,
                      children: [
                        Text(
                          '₱${product.price}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.darkBlue,
                          ),
                        ),
                        Icon(
                          product.available
                              ? Icons.check_circle
                              : Icons.remove_circle_outline,
                          size: 13,
                          color: product.available
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        Text(
                          product.available ? 'Available' : 'Unavailable',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: product.available
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.xSmall,
                      children: [
                        AppButton(
                          label: 'Details',
                          type: AppButtonType.secondary,
                          isFullWidth: false,
                          onPressed: onViewDetails,
                        ),
                        AppButton(
                          label: quantityInCart > 0
                              ? 'Added ($quantityInCart)'
                              : 'Add to Cart',
                          isFullWidth: false,
                          onPressed: product.available ? onAdd : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
