import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../models/product.dart';
import '../../../products/presentation/product_provider.dart';
import '../widgets/product_card.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({
    required this.cart,
    required this.onViewProduct,
    required this.onAddProduct,
    super.key,
  });

  final Map<String, int> cart;
  final ValueChanged<Product> onViewProduct;
  final ValueChanged<Product> onAddProduct;

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _searchController = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productsProvider, _) {
        if (productsProvider.isLoading) {
          return const AppLoadingIndicator.fullScreen(
            message: 'Loading products...',
          );
        }
        if (productsProvider.errorMessage != null) {
          return AppErrorState(
            message: productsProvider.errorMessage!,
            onRetry: productsProvider.loadProducts,
          );
        }
        final products = productsProvider.products;
        if (products.isEmpty) {
          return AppEmptyState(
            title: 'No products available',
            message: 'Please check back soon.',
            icon: Icons.water_drop_outlined,
            actionLabel: 'Retry',
            onAction: productsProvider.loadProducts,
          );
        }
        return _buildCatalog(products);
      },
    );
  }

  Widget _buildCatalog(List<Product> products) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredProducts = products.where((product) {
      final matchesQuery =
          product.name.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      final matchesCategory =
          _category == null ||
          product.name.toLowerCase().contains(_category!.toLowerCase()) ||
          product.categoryLabel.toLowerCase() == _category!.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.large,
      ),
      children: [
        Text('Our water', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          'Illustrative sample products and prices.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.medium),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search water products',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
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
                _categoryChip(category),
                const SizedBox(width: AppSpacing.small),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (filteredProducts.isEmpty)
          AppEmptyState(
            title: 'No products found',
            message: 'Try another search or category.',
            icon: Icons.search_off_rounded,
            actionLabel: 'Clear filters',
            onAction: () {
              _searchController.clear();
              setState(() => _category = null);
            },
          )
        else ...[
          const SectionHeader(title: 'Available products'),
          const SizedBox(height: AppSpacing.small),
          for (final product in filteredProducts) ...[
            ProductCard(
              product: product,
              quantityInCart: widget.cart[product.id] ?? 0,
              onViewDetails: () => widget.onViewProduct(product),
              onAdd: () => widget.onAddProduct(product),
            ),
            const SizedBox(height: AppSpacing.small),
          ],
        ],
      ],
    );
  }

  Widget _categoryChip(String label) {
    final selected = _category == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _category = selected ? null : label),
    );
  }
}
