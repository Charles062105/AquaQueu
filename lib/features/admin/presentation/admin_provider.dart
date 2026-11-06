import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/admin_dashboard_stats.dart';
import '../models/admin_order.dart';
import '../models/admin_product_input.dart';
import '../../../models/order.dart';
import '../../../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider({required this.adminService, required this.adminId}) {
    refreshDashboard();
    _subscription = adminService.watchOrders().listen(
      (orders) {
        if (_isDisposed) return;
        _orders = orders;
        _ordersError = null;
        _isOrdersLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        if (_isDisposed) return;
        _ordersError = AdminServiceFailure.friendlyMessage(error);
        _isOrdersLoading = false;
        notifyListeners();
      },
    );
  }

  final AdminService adminService;
  final String adminId;
  StreamSubscription<List<AdminOrder>>? _subscription;
  AdminDashboardStats? _stats;
  List<AdminOrder> _orders = const [];
  bool _isDashboardLoading = true;
  bool _isOrdersLoading = true;
  bool _isDisposed = false;
  String? _dashboardError;
  String? _ordersError;
  String _searchQuery = '';
  OrderStatus? _statusFilter;
  String? _actionError;
  bool _isActionInProgress = false;

  AdminDashboardStats? get stats => _stats;
  List<AdminOrder> get orders => List.unmodifiable(_orders);
  List<AdminOrder> get filteredOrders =>
      filterOrders(_orders, query: _searchQuery, status: _statusFilter);
  bool get isDashboardLoading => _isDashboardLoading;
  bool get isOrdersLoading => _isOrdersLoading;
  bool get isActionInProgress => _isActionInProgress;
  String? get dashboardError => _dashboardError;
  String? get ordersError => _ordersError;
  String? get actionError => _actionError;
  String get searchQuery => _searchQuery;
  OrderStatus? get statusFilter => _statusFilter;

  static List<AdminOrder> filterOrders(
    Iterable<AdminOrder> orders, {
    String query = '',
    OrderStatus? status,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return List<AdminOrder>.unmodifiable(
      orders.where((entry) {
        final matchesStatus = status == null || entry.order.status == status;
        final matchesQuery =
            normalizedQuery.isEmpty ||
            entry.order.id.toLowerCase().contains(normalizedQuery) ||
            entry.customerName.toLowerCase().contains(normalizedQuery);
        return matchesStatus && matchesQuery;
      }),
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(OrderStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<void> retryOrders() async {
    if (_isDisposed) return;
    await _subscription?.cancel();
    if (_isDisposed) return;
    _ordersError = null;
    _isOrdersLoading = true;
    notifyListeners();
    _subscription = adminService.watchOrders().listen(
      (orders) {
        if (_isDisposed) return;
        _orders = orders;
        _ordersError = null;
        _isOrdersLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        if (_isDisposed) return;
        _ordersError = AdminServiceFailure.friendlyMessage(error);
        _isOrdersLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refreshDashboard() async {
    if (_isDisposed) return;
    _isDashboardLoading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _stats = await adminService.getDashboardStats();
    } catch (error) {
      _dashboardError = AdminServiceFailure.friendlyMessage(error);
    } finally {
      if (!_isDisposed) {
        _isDashboardLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> confirmPayment(String orderId) => _performAction(
    () => adminService.confirmPayment(orderId: orderId, adminId: adminId),
  );

  Future<bool> updateOrderStatus({
    required String orderId,
    required OrderStatus expectedStatus,
    required OrderStatus nextStatus,
  }) => _performAction(
    () => adminService.updateOrderStatus(
      orderId: orderId,
      expectedStatus: expectedStatus,
      nextStatus: nextStatus,
      adminId: adminId,
    ),
  );

  Future<bool> createProduct(AdminProductInput product) => _performAction(
    () => adminService.createProduct(adminId: adminId, product: product),
  );

  Future<bool> updateProduct({
    required String productId,
    required AdminProductInput product,
  }) => _performAction(
    () => adminService.updateProduct(
      adminId: adminId,
      productId: productId,
      product: product,
    ),
  );

  Future<bool> _performAction(Future<void> Function() action) async {
    if (_isActionInProgress) return false;
    _isActionInProgress = true;
    _actionError = null;
    notifyListeners();
    try {
      await action();
      await refreshDashboard();
      return true;
    } catch (error) {
      _actionError = AdminServiceFailure.friendlyMessage(error);
      return false;
    } finally {
      _isActionInProgress = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
