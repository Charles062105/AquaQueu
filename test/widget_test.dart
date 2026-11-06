import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaqueu/app/theme/app_colors.dart';
import 'package:aquaqueu/app/routes.dart';
import 'package:aquaqueu/features/admin/presentation/admin_shell.dart';
import 'package:aquaqueu/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:aquaqueu/features/admin/models/admin_order.dart';
import 'package:aquaqueu/features/customer/presentation/customer_shell.dart';
import 'package:aquaqueu/features/orders/presentation/screens/order_details_screen.dart';
import 'package:aquaqueu/models/order.dart';
import 'package:aquaqueu/features/customer/presentation/screens/product_catalog_screen.dart';
import 'package:aquaqueu/features/products/presentation/product_provider.dart';
import 'package:aquaqueu/models/product.dart';
import 'package:aquaqueu/services/mock/mock_products.dart';
import 'package:aquaqueu/services/admin_service.dart';
import 'package:aquaqueu/services/product_service.dart';

import 'test_dependencies.dart';

Widget _catalogScreen(ProductService service) {
  return ChangeNotifierProvider(
    create: (_) => ProductProvider(service),
    child: MaterialApp(
      home: Scaffold(
        body: ProductCatalogScreen(
          cart: const {},
          onViewProduct: (_) {},
          onAddProduct: (_) {},
        ),
      ),
    ),
  );
}

Future<void> _openHome(
  WidgetTester tester, {
  FakeOrderService? orderService,
  FakeAdminService? adminService,
  bool loginAsAdmin = false,
}) async {
  await tester.pumpWidget(
    createTestApp(
      orderService: orderService,
      adminService: adminService,
      loginAsAdmin: loginAsAdmin,
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'alex@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password123');
  await tester.tap(find.text('Log In'));
  await tester.pumpAndSettle();
}

Future<void> _openCheckout(
  WidgetTester tester, {
  FakeOrderService? orderService,
  String productName = '5-Gallon Purified Water',
}) async {
  await _openHome(tester, orderService: orderService);
  await tester.tap(find.text('Products').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(productName).first);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Continue to Checkout'),
    250,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.text('Continue to Checkout'));
  await tester.pumpAndSettle();
}

Future<void> _scrollCurrentPageDown(WidgetTester tester) async {
  for (var attempt = 0; attempt < 4; attempt++) {
    if (find.text('Place Order').evaluate().isNotEmpty) return;
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('admin role routes to the administrator dashboard', (
    WidgetTester tester,
  ) async {
    await _openHome(tester, loginAsAdmin: true);

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    expect(find.byType(CustomerShell), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer direct navigation to admin is safely gated', (
    WidgetTester tester,
  ) async {
    await _openHome(tester);
    Navigator.of(tester.element(find.byType(CustomerShell)))
        .pushNamed(AppRoutes.admin);
    await tester.pumpAndSettle();

    expect(find.byType(CustomerShell), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);
    expect(find.byType(AdminDashboardScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unrecognized roles do not receive administrator access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp(profileRole: 'owner'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alex@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomerShell), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin order details show customer and stored order data', (
    WidgetTester tester,
  ) async {
    final service = FakeAdminService();
    service.orders.add(
      AdminOrder(
        order: Order(
          id: 'AQ-ADMIN-0001',
          date: DateTime(2026, 11, 6),
          items: const [],
          status: OrderStatus.pending,
          isDelivery: true,
          paymentMethod: 'Cash on Delivery',
          paymentStatus: 'Unpaid',
          subtotal: 100,
          deliveryFee: 30,
          total: 130,
          address: '12 Sample Street',
          deliveryDate: '2026-11-07',
          deliveryTime: '10:00 AM',
        ),
        customerId: 'customer-1',
        customerName: 'Jamie Customer',
        customerEmail: 'jamie@example.com',
        customerPhone: '555-0101',
      ),
    );
    await _openHome(tester, loginAsAdmin: true, adminService: service);
    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('AQ-ADMIN-0001'));
    await tester.pumpAndSettle();

    expect(find.text('Jamie Customer'), findsNWidgets(2));
    expect(find.text('jamie@example.com'), findsOneWidget);
    expect(find.text('555-0101'), findsOneWidget);
    expect(find.text('12 Sample Street'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Confirm order'), findsOneWidget);
    expect(find.text('Cancel order'), findsOneWidget);
    expect(find.text('Mark as Preparing'), findsNothing);
    expect(find.text('Confirm payment received'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin sees a clear status conflict when order changed', (
    WidgetTester tester,
  ) async {
    final service = FakeAdminService()
      ..statusUpdateFailure = const AdminServiceFailure(
        'This order status changed while you were viewing it.',
      );
    service.orders.add(
      AdminOrder(
        order: Order(
          id: 'AQ-ADMIN-CONFLICT',
          date: DateTime(2026, 11, 6),
          items: const [],
          status: OrderStatus.pending,
          isDelivery: false,
          paymentMethod: 'Cash on Pickup',
          subtotal: 100,
          deliveryFee: 0,
          total: 100,
        ),
        customerId: 'customer-1',
        customerName: 'Jamie Customer',
        customerEmail: 'jamie@example.com',
        customerPhone: '555-0101',
      ),
    );
    await _openHome(tester, loginAsAdmin: true, adminService: service);
    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('AQ-ADMIN-CONFLICT'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm order'));
    await tester.pumpAndSettle();

    expect(
      find.text('This order status changed while you were viewing it.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer order details refresh status and pickup timeline', (
    WidgetTester tester,
  ) async {
    final service = FakeOrderService();
    final order = Order(
      id: 'AQ-LIVE-PICKUP',
      date: DateTime(2026, 11, 6, 9),
      items: const [],
      status: OrderStatus.preparing,
      isDelivery: false,
      paymentMethod: 'Cash on Pickup',
      paymentStatus: 'Unpaid',
      subtotal: 100,
      deliveryFee: 0,
      total: 100,
    );
    service.setOrderForTest(order);
    final history = [
      OrderStatusHistoryEntry(
        status: OrderStatus.confirmed,
        changedBy: 'admin-1',
        changedAt: DateTime(2026, 11, 6, 9, 15),
      ),
      OrderStatusHistoryEntry(
        status: OrderStatus.preparing,
        changedBy: 'admin-1',
        changedAt: DateTime(2026, 11, 6, 9, 30),
      ),
    ];
    service.setStatusHistoryForTest(order.id, history);

    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailsScreen(order: order, orderService: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Current status: Preparing'), findsOneWidget);
    expect(find.text('Out for Delivery'), findsNothing);

    service.setOrderForTest(
      Order(
        id: order.id,
        date: order.date,
        items: order.items,
        status: OrderStatus.delivered,
        isDelivery: false,
        paymentMethod: order.paymentMethod,
        paymentStatus: order.paymentStatus,
        subtotal: order.subtotal,
        deliveryFee: 0,
        total: order.total,
      ),
    );
    service.setStatusHistoryForTest(order.id, [
      ...history,
      OrderStatusHistoryEntry(
        status: OrderStatus.delivered,
        changedBy: 'admin-1',
        changedAt: DateTime(2026, 11, 6, 10, 30),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Current status: Delivered'), findsOneWidget);
    expect(find.textContaining('10:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login validates email and password before demo navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login displays an authentication service error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      createTestApp(loginFailureMessage: 'The email or password is incorrect.'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alex@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrect');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('The email or password is incorrect.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome and login flow open the customer home', (
    WidgetTester tester,
  ) async {
    await _openHome(tester);

    expect(find.text('Good day, Alex 👋'), findsOneWidget);
    expect(find.text('Clean Water,\nDelivered to You!'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration validates required and matching fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Complete Registration'));
    await tester.tap(find.text('Complete Registration'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required.'), findsNWidgets(3));
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Create a password.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Alex Santos');
    await tester.enterText(find.byType(TextFormField).at(1), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(2), '09171234567');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      '24 Sample Street',
    );
    await tester.enterText(find.byType(TextFormField).at(4), 'password123');
    await tester.enterText(find.byType(TextFormField).at(5), 'different123');
    await tester.ensureVisible(find.text('Complete Registration'));
    await tester.tap(find.text('Complete Registration'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valid registration opens Home with in-memory profile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Jordan Lee');
    await tester.enterText(fields.at(1), 'jordan@example.com');
    await tester.enterText(fields.at(2), '09171234567');
    await tester.enterText(fields.at(3), '12 Sample Road');
    await tester.enterText(fields.at(4), 'password123');
    await tester.enterText(fields.at(5), 'password123');
    await tester.ensureVisible(find.text('Complete Registration'));
    await tester.tap(find.text('Complete Registration'));
    await tester.pumpAndSettle();

    expect(find.text('Good day, Jordan 👋'), findsOneWidget);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Jordan Lee'), findsOneWidget);
    expect(find.text('jordan@example.com'), findsOneWidget);
    expect(find.text('12 Sample Road'), findsOneWidget);
  });

  testWidgets('product search and category chips filter local products', (
    WidgetTester tester,
  ) async {
    await _openHome(tester);
    await tester.tap(find.text('Products').last);
    await tester.pumpAndSettle();

    expect(find.text('5-Gallon Purified Water'), findsOneWidget);
    expect(find.text('5-Gallon Mineral Water'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('1-Gallon Mineral Water'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1-Gallon Mineral Water'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'mineral');
    await tester.pumpAndSettle();
    expect(find.text('5-Gallon Mineral Water'), findsOneWidget);
    expect(find.text('5-Gallon Purified Water'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Purified'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('5-Gallon Purified Water'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('5-Gallon Purified Water'), findsOneWidget);
    expect(find.text('5-Gallon Mineral Water'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog reports load errors and can retry', (
    WidgetTester tester,
  ) async {
    final service = FakeProductService(error: StateError('Temporary error'));
    await tester.pumpWidget(_catalogScreen(service));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Products could not be loaded. Check your connection and try again.',
      ),
      findsOneWidget,
    );

    service.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('5-Gallon Purified Water'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog shows loading while sample data is prepared', (
    WidgetTester tester,
  ) async {
    final service = FakeProductService(
      delay: const Duration(milliseconds: 300),
    );
    await tester.pumpWidget(_catalogScreen(service));

    expect(find.text('Loading products...'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('5-Gallon Purified Water'), findsOneWidget);
  });

  testWidgets('catalog shows an empty state when no sample products load', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _catalogScreen(FakeProductService(products: const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('No products available'), findsOneWidget);
    expect(find.text('Please check back soon.'), findsOneWidget);
  });

  testWidgets('product details quantity updates subtotal and checkout cart', (
    WidgetTester tester,
  ) async {
    await _openHome(tester);
    await tester.tap(find.text('Products').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5-Gallon Purified Water').first);
    await tester.pumpAndSettle();

    expect(find.text('₱50'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(find.text('₱100'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Continue to Checkout'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Continue to Checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('₱100'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase quantity').last);
    await tester.pumpAndSettle();
    expect(find.text('₱150'), findsOneWidget);
    await _scrollCurrentPageDown(tester);
    expect(find.text('Delivery fee'), findsOneWidget);
    expect(find.text('₱30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pickup checkout creates an order with zero delivery fee', (
    WidgetTester tester,
  ) async {
    await _openHome(tester);
    await tester.tap(find.text('Products').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5-Gallon Mineral Water').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Continue to Checkout'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Continue to Checkout'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pick Up'));
    await tester.pumpAndSettle();
    expect(find.text('Complete delivery address'), findsNothing);
    await _scrollCurrentPageDown(tester);
    expect(find.text('₱0'), findsOneWidget);

    await _scrollCurrentPageDown(tester);
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.textContaining('was submitted'), findsOneWidget);
    await tester.tap(find.text('View orders'));
    await tester.pumpAndSettle();
    expect(find.text('AQ-TEST-0001'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Your cart is empty.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivery checkout requires a preferred date and time', (
    WidgetTester tester,
  ) async {
    await _openHome(tester);
    await tester.tap(find.text('Products').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1-Gallon Purified Water').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Continue to Checkout'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Continue to Checkout'));
    await tester.pumpAndSettle();

    await _scrollCurrentPageDown(tester);
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();
    expect(find.text('Select a delivery date and time.'), findsOneWidget);
    expect(find.text('₱30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivery checkout requires a non-empty address', (
    WidgetTester tester,
  ) async {
    final service = FakeOrderService();
    await _openCheckout(tester, orderService: service);
    await tester.enterText(find.byType(TextFormField).last, '');
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _scrollCurrentPageDown(tester);
    await tester.ensureVisible(find.text('Place Order'));
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsOneWidget);
    expect(service.createOrderCalls, 0);
    expect(find.text('Cart (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate Place Order taps submit only once', (
    WidgetTester tester,
  ) async {
    final service = FakeOrderService(delay: const Duration(milliseconds: 300));
    await _openCheckout(tester, orderService: service);
    await tester.tap(find.text('Pick Up'));
    await tester.pumpAndSettle();
    await _scrollCurrentPageDown(tester);
    await tester.tap(find.text('Place Order'));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.tap(find.text('Place Order'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(service.createOrderCalls, 1);
    expect(service.orders, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable catalog product fails clearly and preserves cart', (
    WidgetTester tester,
  ) async {
    final service = FakeOrderService(
      products: [
        for (final product in MockProducts.all)
          if (product.id == 'purified-5-gallon')
            Product(
              id: product.id,
              name: product.name,
              description: product.description,
              price: product.price,
              category: product.category,
              available: false,
            )
          else
            product,
      ],
    );
    await _openCheckout(tester, orderService: service);
    await tester.tap(find.text('Pick Up'));
    await tester.pumpAndSettle();
    await _scrollCurrentPageDown(tester);
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(find.textContaining('no longer available'), findsOneWidget);
    expect(find.text('Cart (1)'), findsOneWidget);
    expect(service.orders, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changed product price fails clearly and preserves cart', (
    WidgetTester tester,
  ) async {
    final service = FakeOrderService(
      products: [
        for (final product in MockProducts.all)
          if (product.id == 'purified-5-gallon')
            Product(
              id: product.id,
              name: product.name,
              description: product.description,
              price: product.price + 5,
              category: product.category,
            )
          else
            product,
      ],
    );
    await _openCheckout(tester, orderService: service);
    await tester.tap(find.text('Pick Up'));
    await tester.pumpAndSettle();
    await _scrollCurrentPageDown(tester);
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(find.textContaining('price of'), findsOneWidget);
    expect(find.text('Cart (1)'), findsOneWidget);
    expect(service.orders, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart items can be removed from checkout', (
    WidgetTester tester,
  ) async {
    await _openHome(tester);
    await tester.tap(find.text('Products').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5-Gallon Purified Water').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Continue to Checkout'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Continue to Checkout'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove item'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Firestore orders appear in My Orders and show stored snapshots',
    (WidgetTester tester) async {
      await _openHome(tester);
      await tester.tap(find.text('Orders').last);
      await tester.pumpAndSettle();
      expect(find.text('No orders yet'), findsOneWidget);

      await tester.tap(find.text('Products').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5-Gallon Purified Water').first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Continue to Checkout'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Continue to Checkout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick Up'));
      await tester.pumpAndSettle();
      await _scrollCurrentPageDown(tester);
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View orders'));
      await tester.pumpAndSettle();
      expect(find.text('AQ-TEST-0001'), findsOneWidget);
      expect(find.text('Pending'), findsWidgets);
      await tester.tap(find.text('View details').first);
      await tester.pumpAndSettle();
      expect(find.text('Order details'), findsOneWidget);
      expect(find.text('5-Gallon Purified Water'), findsOneWidget);
      expect(find.text('Cash on Pickup'), findsOneWidget);
      expect(find.text('Unpaid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile navigation and local information editing work', (
    WidgetTester tester,
  ) async {
    await _openHome(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Santos'), findsOneWidget);

    await tester.tap(find.text('Personal Information'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name-input')),
      'Alex Rivera',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('profile-name-input')))
          .controller
          ?.text,
      'Alex Rivera',
    );
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-save-button')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-save-button')));
    await tester.pumpAndSettle();
    expect(find.text('Alex Rivera'), findsOneWidget);

    await tester.tap(find.text('My Orders').last);
    await tester.pumpAndSettle();
    expect(find.text('No orders yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home categories filter products and Cart has an empty state', (
    WidgetTester tester,
  ) async {
    await _openHome(tester);
    await tester.tap(find.text('5-Gallon'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('5-Gallon Purified Water'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('5-Gallon Purified Water'), findsOneWidget);
    expect(find.text('1-Gallon Purified Water'), findsNothing);

    await tester.tap(find.text('Cart').last);
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty.'), findsOneWidget);
    expect(find.text('Browse products'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome and customer home fit common Android viewport sizes', (
    WidgetTester tester,
  ) async {
    const sizes = [Size(360, 800), Size(390, 844), Size(412, 915)];
    await tester.binding.setSurfaceSize(sizes.first);
    await _openHome(tester);
    expect(tester.takeException(), isNull);
    for (final size in sizes.skip(1)) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('customer tabs fit a small phone with larger text', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    await _openHome(tester);

    await tester.tap(find.text('Products').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5-Gallon Purified Water').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Continue to Checkout'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Continue to Checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Cart and Checkout'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final tab in ['Products', 'Cart', 'Orders', 'Profile', 'Home']) {
      final destination = tab == 'Cart'
          ? find.textContaining('Cart').last
          : find.text(tab).last;
      await tester.tap(destination);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Tab: $tab');
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shared theme keeps the AquaQueue background', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor,
      AppColors.background,
    );
  });
}
