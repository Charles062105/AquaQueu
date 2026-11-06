import 'package:flutter/material.dart';

import '../core/constants/app_spacing.dart';
import '../models/order.dart';
import '../models/product.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const products = '/products';
  static const productDetails = '/product-details';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const orderDetails = '/order-details';
  static const profile = '/profile';
  static const admin = '/admin';
  static const adminOrders = '/admin/orders';
  static const adminProducts = '/admin/products';
}

class ProductDetailsRouteArguments {
  const ProductDetailsRouteArguments({
    required this.product,
    required this.onAddToCart,
    required this.onCheckout,
  });

  final Product product;
  final ValueChanged<int> onAddToCart;
  final VoidCallback onCheckout;
}

class OrderDetailsRouteArguments {
  const OrderDetailsRouteArguments(this.order);

  final Order order;
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This page is unavailable.'),
              const SizedBox(height: AppSpacing.medium),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Return to AquaQueue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
