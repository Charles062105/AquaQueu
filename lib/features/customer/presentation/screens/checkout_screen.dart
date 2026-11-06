import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/quantity_selector.dart';
import '../../../../models/cart_item.dart';
import '../../../../models/order.dart';
import '../../../../models/delivery_location.dart';
import '../../../../services/order_service.dart';
import 'location_picker_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.items,
    required this.customerId,
    required this.customerAddress,
    required this.orderService,
    required this.onQuantityChanged,
    required this.onRemoveItem,
    required this.onBrowseProducts,
    required this.onOrderPlaced,
    required this.onViewOrders,
    required this.onProductsChanged,
    super.key,
  });

  final List<CartItem> items;
  final String customerId;
  final String customerAddress;
  final OrderService orderService;
  final void Function(String productId, int quantity) onQuantityChanged;
  final ValueChanged<String> onRemoveItem;
  final VoidCallback onBrowseProducts;
  final ValueChanged<Order> onOrderPlaced;
  final VoidCallback onViewOrders;
  final VoidCallback onProductsChanged;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<CartItem> _items;
  late final TextEditingController _addressController;
  bool _isDelivery = true;
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  DeliveryLocation? _deliveryLocation;
  bool _isSubmitting = false;
  String? _orderId;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
    _addressController = TextEditingController(text: widget.customerAddress);
  }

  @override
  void didUpdateWidget(covariant CheckoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _items = List.of(widget.items);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  int get _subtotal => _items.fold(0, (total, item) => total + item.subtotal);

  int get _deliveryFee => _isDelivery ? AppConstants.deliveryFee : 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart and Checkout')),
        body: AppEmptyState(
          title: 'Your cart is empty.',
          message: 'Browse the water catalog to add products to your cart.',
          icon: Icons.shopping_cart_outlined,
          actionLabel: 'Browse products',
          onAction: widget.onBrowseProducts,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cart and Checkout')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.mediumLarge,
              AppSpacing.small,
              AppSpacing.mediumLarge,
              AppSpacing.large,
            ),
            children: [
              Text('Order summary', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.smallMedium),
              for (final item in _items) ...[
                _OrderItemTile(
                  item: item,
                  onQuantityChanged: (quantity) =>
                      _changeQuantity(item.product.id, quantity),
                  onRemove: () => _removeItem(item.product.id),
                ),
                const SizedBox(height: AppSpacing.smallMedium),
              ],
              const SizedBox(height: AppSpacing.smallMedium),
              Text(
                'How would you like to receive it?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.smallMedium),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.storefront_outlined),
                    label: Text('Pick Up'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.delivery_dining_outlined),
                    label: Text('Delivery'),
                  ),
                ],
                selected: {_isDelivery},
                onSelectionChanged: _isSubmitting
                    ? null
                    : (selection) {
                        setState(() {
                          _isDelivery = selection.first;
                          _orderId = null;
                        });
                      },
              ),
              const SizedBox(height: AppSpacing.medium),
              if (_isDelivery) ...[
                Text('Delivery information', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.smallMedium),
                AppTextField(
                  label: 'Complete delivery address',
                  controller: _addressController,
                  prefixIcon: Icons.location_on_outlined,
                  validator: _requiredValidator,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    _orderId = null;
                    if (_submitError != null) {
                      setState(() => _submitError = null);
                    }
                  },
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: AppSpacing.small),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _selectDeliveryLocation,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    _deliveryLocation == null
                        ? 'Pin delivery location (optional)'
                        : 'Delivery location pinned',
                  ),
                ),
                const SizedBox(height: AppSpacing.smallMedium),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    _preferredDate == null
                        ? 'Choose preferred date'
                        : '${_preferredDate!.month}/${_preferredDate!.day}/${_preferredDate!.year}',
                  ),
                ),
                if (_preferredDate == null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.smallMedium,
                      top: AppSpacing.xSmall,
                    ),
                    child: Text(
                      'Choose a preferred delivery date.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.small),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _selectTime,
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    _preferredTime?.format(context) ?? 'Choose preferred time',
                  ),
                ),
                if (_preferredTime == null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.smallMedium,
                      top: AppSpacing.xSmall,
                    ),
                    child: Text(
                      'Choose a preferred delivery time.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.medium),
              ],
              Text('Payment method', style: theme.textTheme.titleLarge),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.payments_outlined),
                title: Text(
                  _isDelivery ? 'Cash on Delivery' : 'Cash on Pickup',
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              _PriceRow(label: 'Subtotal', amount: _subtotal),
              const SizedBox(height: AppSpacing.small),
              _PriceRow(label: 'Delivery fee', amount: _deliveryFee),
              const Divider(height: 24),
              _PriceRow(
                label: 'Total',
                amount: _subtotal + _deliveryFee,
                isTotal: true,
              ),
              const SizedBox(height: AppSpacing.medium),
              AppButton(
                label: 'Place Order',
                isLoading: _isSubmitting,
                onPressed: _submitOrder,
              ),
              if (_submitError != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  _submitError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.small),
              Text(
                'Pay in cash when your order is delivered or collected.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required.';
    return null;
  }

  void _changeQuantity(String productId, int quantity) {
    if (_isSubmitting) return;
    setState(() {
      _orderId = null;
      _items = [
        for (final item in _items)
          if (item.product.id == productId)
            CartItem(product: item.product, quantity: quantity)
          else
            item,
      ];
    });
    widget.onQuantityChanged(productId, quantity);
  }

  void _removeItem(String productId) {
    if (_isSubmitting) return;
    setState(() {
      _orderId = null;
      _items.removeWhere((item) => item.product.id == productId);
    });
    widget.onRemoveItem(productId);
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null && mounted) {
      setState(() {
        _preferredDate = selected;
        _orderId = null;
      });
    }
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _preferredTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (selected != null && mounted) {
      setState(() {
        _preferredTime = selected;
        _orderId = null;
      });
    }
  }

  Future<void> _selectDeliveryLocation() async {
    final location = await Navigator.of(context).push<DeliveryLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: _deliveryLocation),
      ),
    );
    if (location != null && mounted) {
      setState(() {
        _deliveryLocation = location;
        _orderId = null;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    if (_isDelivery && _addressController.text.trim().isEmpty) {
      setState(() => _submitError = 'This field is required.');
      return;
    }
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (_items.isEmpty) {
      setState(() => _submitError = 'Add at least one product to your cart.');
      return;
    }
    if (_isDelivery && (_preferredDate == null || _preferredTime == null)) {
      setState(() => _submitError = 'Select a delivery date and time.');
      return;
    }
    if (_isDelivery && _isDateBeforeToday(_preferredDate!)) {
      setState(
        () => _submitError = 'Choose a delivery date that is not in the past.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    final orderId = _orderId ??= widget.orderService.generateOrderId();
    try {
      final order = await widget.orderService.createOrder(
        orderId: orderId,
        customerId: widget.customerId,
        quantities: {for (final item in _items) item.product.id: item.quantity},
        displayedPrices: {
          for (final item in _items) item.product.id: item.product.price,
        },
        isDelivery: _isDelivery,
        deliveryAddress: _isDelivery ? _addressController.text : null,
        preferredDate: _isDelivery ? _preferredDate : null,
        preferredTime: _isDelivery ? _preferredTime?.format(context) : null,
        deliveryLocation: _isDelivery ? _deliveryLocation : null,
      );
      if (!mounted) return;
      widget.onOrderPlaced(order);
      setState(() => _isSubmitting = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
          ),
          title: const Text('Order placed'),
          content: Text(
            'Order ${order.id} was submitted. You can view it in My Orders.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onViewOrders();
              },
              child: const Text('View orders'),
            ),
          ],
        ),
      );
    } on OrderServiceFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError = error.message;
      });
      if (error is OrderValidationFailure &&
          (error.message.contains('price') ||
              error.message.contains('available'))) {
        widget.onProductsChanged();
      }
    }
  }

  bool _isDateBeforeToday(DateTime date) {
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.smallMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop_outlined, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.smallMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '₱${item.subtotal}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                QuantitySelector(
                  quantity: item.quantity,
                  onChanged: onQuantityChanged,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove item',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final int amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: AppColors.darkBlue)
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text('₱$amount', style: style),
      ],
    );
  }
}
