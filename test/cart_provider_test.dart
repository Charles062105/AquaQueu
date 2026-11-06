import 'package:flutter_test/flutter_test.dart';

import 'package:aquaqueu/core/constants/app_constants.dart';
import 'package:aquaqueu/features/customer/presentation/cart_provider.dart';
import 'package:aquaqueu/services/mock/mock_products.dart';

import 'test_dependencies.dart';

void main() {
  test('cart stores IDs and quantities and calculates from catalog prices', () {
    final cart = CartProvider();
    final purified = MockProducts.byId('purified-5-gallon');
    final mineral = MockProducts.byId('mineral-5-gallon');

    expect(cart.addProduct(purified, quantity: 2), isTrue);
    expect(cart.addProduct(mineral), isTrue);
    expect(cart.quantities, {'purified-5-gallon': 2, 'mineral-5-gallon': 1});

    final subtotal = cart.quantities.entries.fold<int>(0, (total, entry) {
      final product = MockProducts.byId(entry.key);
      return total + product.price * entry.value;
    });
    expect(subtotal, 160);

    expect(cart.setQuantity('purified-5-gallon', 3), isTrue);
    expect(cart.quantities['purified-5-gallon'], 3);
    expect(cart.setQuantity('purified-5-gallon', 0), isFalse);
    expect(cart.quantities['purified-5-gallon'], 3);
    cart.dispose();
  });

  test(
    'unavailable products cannot be added and pickup has no delivery fee',
    () async {
      final cart = CartProvider();
      final unavailable = MockProducts.byId('mineral-1-gallon-unavailable');

      expect(unavailable.available, isFalse);
      expect(cart.addProduct(unavailable), isFalse);
      expect(cart.quantities, isEmpty);
      expect(AppConstants.deliveryFee, 30);

      final service = FakeOrderService();
      final product = MockProducts.byId('purified-5-gallon');
      final order = await service.createOrder(
        orderId: service.generateOrderId(),
        customerId: 'test-customer',
        quantities: {product.id: 1},
        displayedPrices: {product.id: product.price},
        isDelivery: false,
        deliveryAddress: null,
        preferredDate: null,
        preferredTime: null,
      );
      expect(order.deliveryFee, 0);
      cart.dispose();
    },
  );

  test('removing the final item empties the cart', () {
    final cart = CartProvider();
    final product = MockProducts.byId('purified-5-gallon');
    cart.addProduct(product);
    cart.removeProduct(product.id);

    expect(cart.isEmpty, isTrue);
    expect(cart.itemCount, 0);
    cart.dispose();
  });
}
