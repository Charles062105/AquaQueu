import 'dart:async';

import 'package:aquaqueu/app/app.dart';
import 'package:aquaqueu/core/constants/app_constants.dart';
import 'package:aquaqueu/features/admin/models/admin_dashboard_stats.dart';
import 'package:aquaqueu/features/admin/models/admin_order.dart';
import 'package:aquaqueu/features/admin/models/admin_product_input.dart';
import 'package:aquaqueu/models/app_user.dart';
import 'package:aquaqueu/models/order.dart';
import 'package:aquaqueu/models/delivery_location.dart';
import 'package:aquaqueu/models/order_item.dart';
import 'package:aquaqueu/models/product.dart';
import 'package:aquaqueu/services/auth_service.dart';
import 'package:aquaqueu/services/admin_service.dart';
import 'package:aquaqueu/services/mock/mock_products.dart';
import 'package:aquaqueu/services/order_service.dart';
import 'package:aquaqueu/services/product_service.dart';
import 'package:aquaqueu/services/user_service.dart';

AquaQueueApp createTestApp({
  String? loginFailureMessage,
  FakeOrderService? orderService,
  FakeAdminService? adminService,
  bool loginAsAdmin = false,
  String? profileRole,
}) {
  final userService = FakeUserService();
  final authService = FakeAuthService(userService)
    ..loginFailureMessage = loginFailureMessage
    ..loginRole = profileRole ?? (loginAsAdmin ? 'admin' : 'customer');
  return AquaQueueApp(
    authService: authService,
    userService: userService,
    productService: FakeProductService(),
    orderService: orderService ?? FakeOrderService(),
    adminService: adminService ?? FakeAdminService(),
  );
}

class FakeUserService implements UserService {
  final Map<String, AppUser> profiles = {};

  @override
  Future<AppUser> getProfile(String uid) async {
    return profiles.putIfAbsent(
      uid,
      () => AppUser(
        uid: uid,
        fullName: 'Alex Santos',
        email: 'alex@example.com',
        phoneNumber: '09171234567',
        address: '24 Sample Street',
        role: 'customer',
      ),
    );
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required String address,
  }) async {
    final existing = await getProfile(uid);
    profiles[uid] = existing.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      address: address,
    );
  }
}

class FakeAuthService implements AuthService {
  FakeAuthService(this.userService);

  final FakeUserService userService;
  final StreamController<AuthIdentity?> _changes =
      StreamController<AuthIdentity?>.broadcast();
  AuthIdentity? _currentUser;
  String? loginFailureMessage;
  String loginRole = 'customer';

  @override
  AuthIdentity? get currentUser => _currentUser;

  @override
  Stream<AuthIdentity?> get authStateChanges => _changes.stream;

  @override
  Future<void> login({required String email, required String password}) async {
    final failureMessage = loginFailureMessage;
    if (failureMessage != null) throw AuthFailure(failureMessage);
    _currentUser = AuthIdentity(uid: 'test-user', email: email);
    userService.profiles.putIfAbsent(
      _currentUser!.uid,
      () => AppUser(
        uid: _currentUser!.uid,
        fullName: 'Alex Santos',
        email: email,
        phoneNumber: '09171234567',
        address: '24 Sample Street',
        role: loginRole,
      ),
    );
    _changes.add(_currentUser);
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    required String password,
  }) async {
    _currentUser = AuthIdentity(uid: 'test-user', email: email);
    userService.profiles[_currentUser!.uid] = AppUser(
      uid: _currentUser!.uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
      role: 'customer',
    );
    _changes.add(_currentUser);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _changes.add(null);
  }
}

class FakeProductService implements ProductService {
  FakeProductService({
    this.products = MockProducts.all,
    this.delay = Duration.zero,
    this.error,
  });

  final List<Product> products;
  final Duration delay;
  Object? error;

  @override
  Future<List<Product>> getProducts() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return products;
  }
}

class FakeOrderService implements OrderService {
  FakeOrderService({
    this.products = MockProducts.all,
    this.delay = Duration.zero,
  });

  List<Product> products;
  final Duration delay;
  final Map<String, Order> _ordersById = {};
  final StreamController<List<Order>> _changes =
      StreamController<List<Order>>.broadcast();
  final Map<String, List<OrderStatusHistoryEntry>> _historyByOrderId = {};
  final StreamController<String> _historyChanges =
      StreamController<String>.broadcast();
  int createOrderCalls = 0;
  String? failureMessage;

  List<Order> get orders => List.unmodifiable(
    _ordersById.values.toList()
      ..sort((first, second) => second.date.compareTo(first.date)),
  );

  @override
  String generateOrderId() =>
      'AQ-TEST-${(_ordersById.length + 1).toString().padLeft(4, '0')}';

  @override
  Future<Order> createOrder({
    required String orderId,
    required String customerId,
    required Map<String, int> quantities,
    required Map<String, int> displayedPrices,
    required bool isDelivery,
    required String? deliveryAddress,
    required DateTime? preferredDate,
    required String? preferredTime,
    DeliveryLocation? deliveryLocation,
  }) async {
    createOrderCalls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final oldOrder = _ordersById[orderId];
    if (oldOrder != null) return oldOrder;
    if (failureMessage != null) {
      throw OrderServiceFailure(failureMessage!);
    }
    if (quantities.isEmpty) {
      throw const OrderValidationFailure('Your cart is empty.');
    }
    if (quantities.length > 3 ||
        quantities.values.any((quantity) => quantity < 1 || quantity > 99)) {
      throw const OrderValidationFailure('Invalid product quantity.');
    }
    if (isDelivery &&
        (deliveryAddress == null ||
            deliveryAddress.trim().isEmpty ||
            preferredDate == null ||
            preferredTime == null)) {
      throw const OrderValidationFailure(
        'Enter an address and select a delivery date and time.',
      );
    }
    if (isDelivery && _isBeforeToday(preferredDate!)) {
      throw const OrderValidationFailure(
        'Choose a delivery date that is not in the past.',
      );
    }

    final orderItems = <OrderItem>[];
    var subtotal = 0;
    for (final entry in quantities.entries) {
      final matches = products.where((product) => product.id == entry.key);
      if (matches.isEmpty || !matches.first.available) {
        throw const OrderValidationFailure(
          'A product in your cart is no longer available.',
        );
      }
      final product = matches.first;
      if (displayedPrices[entry.key] != product.price) {
        throw OrderValidationFailure(
          'The price of ${product.name} has changed. Review the updated cart.',
        );
      }
      orderItems.add(OrderItem(product: product, quantity: entry.value));
      subtotal += product.price * entry.value;
    }
    final fee = isDelivery ? AppConstants.deliveryFee : 0;
    final order = Order(
      id: orderId,
      date: DateTime.now(),
      items: orderItems,
      status: OrderStatus.pending,
      isDelivery: isDelivery,
      paymentMethod: isDelivery ? 'Cash on Delivery' : 'Cash on Pickup',
      paymentStatus: 'Unpaid',
      subtotal: subtotal,
      deliveryFee: fee,
      total: subtotal + fee,
      address: isDelivery ? deliveryAddress?.trim() : null,
      deliveryDate: isDelivery ? _dateString(preferredDate!) : null,
      deliveryTime: isDelivery ? preferredTime : null,
      deliveryLocation: isDelivery ? deliveryLocation : null,
    );
    _ordersById[orderId] = order;
    _changes.add(orders);
    return order;
  }

  @override
  Stream<List<Order>> watchMyOrders(String customerId) async* {
    yield orders;
    yield* _changes.stream;
  }

  @override
  Future<List<Order>> getMyOrders(String customerId) async => orders;

  @override
  Stream<Order> watchOrder(String orderId) async* {
    final existing = _ordersById[orderId];
    if (existing != null) yield existing;
    await for (final changedOrders in _changes.stream) {
      for (final order in changedOrders) {
        if (order.id == orderId) yield order;
      }
    }
  }

  @override
  Stream<List<OrderStatusHistoryEntry>> watchStatusHistory(
    String orderId,
  ) async* {
    yield List.unmodifiable(_historyByOrderId[orderId] ?? const []);
    await for (final changedOrderId in _historyChanges.stream) {
      if (changedOrderId == orderId) {
        yield List.unmodifiable(_historyByOrderId[orderId] ?? const []);
      }
    }
  }

  void setOrderForTest(Order order) {
    _ordersById[order.id] = order;
    _changes.add(orders);
  }

  void setStatusHistoryForTest(
    String orderId,
    List<OrderStatusHistoryEntry> history,
  ) {
    _historyByOrderId[orderId] = List.unmodifiable(history);
    _historyChanges.add(orderId);
  }

  static String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static bool _isBeforeToday(DateTime date) {
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }
}

class FakeAdminService implements AdminService {
  final List<AdminOrder> orders = [];
  final List<String> recordedActions = [];
  final StreamController<List<AdminOrder>> _changes =
      StreamController<List<AdminOrder>>.broadcast();
  Object? failure;
  Object? statusUpdateFailure;

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    if (failure != null) throw failure!;
    return AdminDashboardStats.fromOrders(orders.map((entry) => entry.order));
  }

  @override
  Stream<List<AdminOrder>> watchOrders() async* {
    yield List.unmodifiable(orders);
    yield* _changes.stream;
  }

  @override
  Future<void> confirmPayment({
    required String orderId,
    required String adminId,
  }) async {
    recordedActions.add('payment_confirmed:$adminId:$orderId');
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus expectedStatus,
    required OrderStatus nextStatus,
    required String adminId,
  }) async {
    if (statusUpdateFailure != null) throw statusUpdateFailure!;
    final index = orders.indexWhere((entry) => entry.order.id == orderId);
    if (index < 0 || orders[index].order.status != expectedStatus) {
      throw const AdminServiceFailure(
        'This order status changed while you were viewing it.',
      );
    }
    final entry = orders[index];
    final current = entry.order;
    orders[index] = AdminOrder(
      order: Order(
        id: current.id,
        date: current.date,
        items: current.items,
        status: nextStatus,
        isDelivery: current.isDelivery,
        paymentMethod: current.paymentMethod,
        paymentStatus: current.paymentStatus,
        subtotal: current.subtotal,
        deliveryFee: current.deliveryFee,
        total: current.total,
        address: current.address,
        deliveryDate: current.deliveryDate,
        deliveryTime: current.deliveryTime,
      ),
      customerId: entry.customerId,
      customerName: entry.customerName,
      customerEmail: entry.customerEmail,
      customerPhone: entry.customerPhone,
    );
    recordedActions.add(
      'order_status_changed:$adminId:$orderId:${nextStatus.label}',
    );
    _changes.add(List.unmodifiable(orders));
  }

  @override
  Future<String> createProduct({
    required String adminId,
    required AdminProductInput product,
  }) async {
    recordedActions.add('product_created:$adminId');
    return 'new-product';
  }

  @override
  Future<void> updateProduct({
    required String adminId,
    required String productId,
    required AdminProductInput product,
  }) async {
    recordedActions.add('product_edited:$adminId:$productId');
  }
}
