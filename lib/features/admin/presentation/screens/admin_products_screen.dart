import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../models/product.dart';
import '../../../products/presentation/product_provider.dart';
import '../../models/admin_product_input.dart';
import '../admin_provider.dart';

class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProductProvider, AdminProvider>(
      builder: (context, products, admin, _) {
        if (products.isLoading && products.products.isEmpty) {
          return const AppLoadingIndicator.fullScreen(
            message: 'Loading products...',
          );
        }
        if (products.errorMessage != null && products.products.isEmpty) {
          return AppErrorState(
            message: products.errorMessage!,
            onRetry: products.loadProducts,
          );
        }
        return RefreshIndicator(
          onRefresh: products.loadProducts,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.medium),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: admin.isActionInProgress
                      ? null
                      : () => _createProduct(context, products, admin),
                  icon: const Icon(Icons.add),
                  label: const Text('Add product'),
                ),
              ),
              if (products.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  products.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (admin.actionError != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  admin.actionError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              if (products.products.isEmpty)
                const AppEmptyState(
                  title: 'No products yet',
                  message: 'Add a product to make it available in the catalog.',
                  icon: Icons.water_drop_outlined,
                )
              else
                for (final product in products.products) ...[
                  _ProductCard(
                    product: product,
                    onEdit: () =>
                        _editProduct(context, products, admin, product),
                    onToggleAvailability: () =>
                        _toggleAvailability(context, products, admin, product),
                  ),
                  const SizedBox(height: AppSpacing.small),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _createProduct(
    BuildContext context,
    ProductProvider products,
    AdminProvider admin,
  ) async {
    final input = await showDialog<AdminProductInput>(
      context: context,
      builder: (_) => const _ProductEditorDialog(),
    );
    if (input == null || !context.mounted) return;
    final success = await admin.createProduct(input);
    if (!context.mounted) return;
    if (success) {
      await products.loadProducts();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Product added.')));
      }
    } else {
      _showActionError(context, admin);
    }
  }

  Future<void> _editProduct(
    BuildContext context,
    ProductProvider products,
    AdminProvider admin,
    Product product,
  ) async {
    final input = await showDialog<AdminProductInput>(
      context: context,
      builder: (_) => _ProductEditorDialog(product: product),
    );
    if (input == null || !context.mounted) return;
    final success = await admin.updateProduct(
      productId: product.id,
      product: input,
    );
    if (!context.mounted) return;
    if (success) {
      await products.loadProducts();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Product updated.')));
      }
    } else {
      _showActionError(context, admin);
    }
  }

  Future<void> _toggleAvailability(
    BuildContext context,
    ProductProvider products,
    AdminProvider admin,
    Product product,
  ) async {
    final input = AdminProductInput(
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category,
      available: !product.available,
      imageUrl: product.imageUrl,
    );
    final success = await admin.updateProduct(
      productId: product.id,
      product: input,
    );
    if (!context.mounted) return;
    if (success) {
      await products.loadProducts();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product.available
                  ? 'Product disabled. Existing order snapshots are unchanged.'
                  : 'Product enabled.',
            ),
          ),
        );
      }
    } else {
      _showActionError(context, admin);
    }
  }

  void _showActionError(BuildContext context, AdminProvider admin) {
    final error = admin.actionError;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onToggleAvailability,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;

  @override
  Widget build(BuildContext context) {
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
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  product.available
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  color: product.available
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.xSmall),
                Text(product.available ? 'Available' : 'Disabled'),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(product.description),
            const SizedBox(height: AppSpacing.small),
            Text(
              '${AppFormatters.currency(product.price)} · '
              '${product.categoryLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                child: Text(
                  product.imageUrl!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onToggleAvailability,
                  icon: Icon(
                    product.available
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  label: Text(product.available ? 'Disable' : 'Enable'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductEditorDialog extends StatefulWidget {
  const _ProductEditorDialog({this.product});

  final Product? product;

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  late ProductCategory _category;
  late bool _available;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    _imageUrlController = TextEditingController(text: product?.imageUrl ?? '');
    _category = product?.category ?? ProductCategory.purified;
    _available = product?.available ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add product' : 'Edit product'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (_) => _errors['name'],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  maxLength: 2000,
                  validator: (value) => (value?.length ?? 0) > 2000
                      ? 'Use 2000 characters or fewer.'
                      : null,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '₱ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  validator: (_) => _errors['price'],
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://example.com/image.jpg',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (_) => _errors['imageUrl'],
                ),
                const SizedBox(height: AppSpacing.small),
                if (widget.product == null)
                  DropdownButtonFormField<ProductCategory>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(
                        value: ProductCategory.purified,
                        child: Text('Purified'),
                      ),
                      DropdownMenuItem(
                        value: ProductCategory.mineral,
                        child: Text('Mineral'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  )
                else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Category'),
                    subtitle: Text(_category.name),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available for ordering'),
                  value: _available,
                  onChanged: (value) => setState(() => _available = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save product')),
      ],
    );
  }

  Map<String, String> get _errors => AdminProductInput.validate(
    name: _nameController.text,
    price: _priceController.text,
    imageUrl: _imageUrlController.text,
  );

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;
    final price = int.tryParse(_priceController.text.trim());
    if (!isValid || price == null) {
      return;
    }
    Navigator.of(context).pop(
      AdminProductInput(
        name: _nameController.text,
        description: _descriptionController.text,
        price: price,
        category: _category,
        available: _available,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
      ),
    );
  }
}
