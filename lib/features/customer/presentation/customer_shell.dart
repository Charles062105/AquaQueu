import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/authentication/presentation/auth_provider.dart';
import '../../../features/customer/presentation/cart_provider.dart';
import '../../../features/orders/presentation/orders_provider.dart';
import '../../../features/orders/presentation/screens/orders_screen.dart';
import '../../../features/products/presentation/product_provider.dart';
import '../../../features/profile/presentation/screens/profile_screen.dart';
import '../../../models/app_user.dart';
import '../../../models/cart_item.dart';
import '../../../models/order.dart';
import '../../../models/product.dart';
import '../../../services/order_service.dart';
import '../../../services/product_service.dart';
import 'screens/checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_catalog_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    required this.user,
    required this.productService,
    required this.orderService,
    this.initialTab = 0,
    super.key,
  });

  final int initialTab;
  final AppUser user;
  final ProductService productService;
  final OrderService orderService;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int _selectedTab = widget.initialTab;
  late AppUser _user = widget.user;
  late final ProductProvider _productProvider = ProductProvider(
    widget.productService,
  );
  late final CartProvider _cartProvider = CartProvider();
  late final OrdersProvider _ordersProvider = OrdersProvider(
    orderService: widget.orderService,
    customerId: widget.user.uid,
  );

  @override
  void didUpdateWidget(covariant CustomerShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) _user = widget.user;
  }

  @override
  void dispose() {
    _productProvider.dispose();
    _cartProvider.dispose();
    _ordersProvider.dispose();
    super.dispose();
  }

  List<CartItem> _cartItems(
    Map<String, int> quantities,
    List<Product> products,
  ) {
    final productsById = {for (final product in products) product.id: product};
    return [
      for (final entry in quantities.entries)
        CartItem(
          product:
              productsById[entry.key] ??
              Product(
                id: entry.key,
                name: 'Unavailable product',
                description: '',
                price: 0,
                category: ProductCategory.purified,
                available: false,
              ),
          quantity: entry.value,
        ),
    ];
  }

  void _addToCart(Product product, int quantity) {
    if (_cartProvider.addProduct(product, quantity: quantity)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          product.available
              ? _cartProvider.quantities.length >=
                            CartProvider.maximumDistinctProducts &&
                        !_cartProvider.quantities.containsKey(product.id)
                    ? 'An order can include at most three different products.'
                    : 'Quantity must be between 1 and 99.'
              : '${product.name} is no longer available.',
        ),
      ),
    );
  }

  void _setCartQuantity(String productId, int quantity) {
    if (!_cartProvider.setQuantity(productId, quantity)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be between 1 and 99.')),
      );
    }
  }

  void _openProduct(Product product) {
    Navigator.of(context).pushNamed(
      AppRoutes.productDetails,
      arguments: ProductDetailsRouteArguments(
        product: product,
        onAddToCart: (quantity) => _addToCart(product, quantity),
        onCheckout: () {
          Navigator.of(context).pop();
          setState(() => _selectedTab = 2);
        },
      ),
    );
  }

  void _openOrder(Order order) {
    Navigator.of(context).pushNamed(
      AppRoutes.orderDetails,
      arguments: OrderDetailsRouteArguments(order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProductProvider>.value(value: _productProvider),
        ChangeNotifierProvider<CartProvider>.value(value: _cartProvider),
        ChangeNotifierProvider<OrdersProvider>.value(value: _ordersProvider),
      ],
      child: Consumer3<ProductProvider, CartProvider, OrdersProvider>(
        builder: (context, products, cart, orders, _) {
          final cartItems = _cartItems(cart.quantities, products.products);
          final tabs = [
            HomeScreen(
              products: products.products,
              productsLoading: products.isLoading,
              productsError: products.errorMessage,
              onRetryProducts: products.loadProducts,
              orders: orders.orders,
              ordersLoading: orders.isLoading,
              ordersError: orders.errorMessage,
              onRetryOrders: orders.reload,
              cart: cart.quantities,
              user: _user,
              onBrowseProducts: () => setState(() => _selectedTab = 1),
              onViewProduct: _openProduct,
              onAddProduct: (product) => _addToCart(product, 1),
              onViewOrders: () => setState(() => _selectedTab = 3),
            ),
            ProductCatalogScreen(
              cart: cart.quantities,
              onViewProduct: _openProduct,
              onAddProduct: (product) => _addToCart(product, 1),
            ),
            CheckoutScreen(
              items: cartItems,
              customerId: _user.uid,
              customerAddress: _user.address,
              orderService: widget.orderService,
              onQuantityChanged: _setCartQuantity,
              onRemoveItem: cart.removeProduct,
              onBrowseProducts: () => setState(() => _selectedTab = 1),
              onOrderPlaced: (_) => cart.clear(),
              onViewOrders: () => setState(() => _selectedTab = 3),
              onProductsChanged: products.loadProducts,
            ),
            OrdersScreen(
              orders: orders.orders,
              isLoading: orders.isLoading,
              errorMessage: orders.errorMessage,
              onRetry: orders.reload,
              onViewOrder: _openOrder,
            ),
            ProfileScreen(
              user: _user,
              onUserChanged: context.read<AuthProvider>().updateProfile,
              onViewOrders: () => setState(() => _selectedTab = 3),
              onLogout: () async {
                await context.read<AuthProvider>().logout();
                cart.clear();
              },
            ),
          ];

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              bottom: false,
              child: IndexedStack(index: _selectedTab, children: tabs),
            ),
            bottomNavigationBar: NavigationBar(
              height: 88,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: _selectedTab,
              onDestinationSelected: (index) =>
                  setState(() => _selectedTab = index),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.water_drop_outlined),
                  selectedIcon: Icon(Icons.water_drop_rounded),
                  label: 'Products',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  selectedIcon: const Icon(Icons.shopping_cart_rounded),
                  label: cart.itemCount > 0
                      ? 'Cart (${cart.itemCount})'
                      : 'Cart',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Orders',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
