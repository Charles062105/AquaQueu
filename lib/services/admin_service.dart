import '../features/admin/models/admin_dashboard_stats.dart';
import '../features/admin/models/admin_order.dart';
import '../features/admin/models/admin_product_input.dart';
import '../models/order.dart';

abstract interface class AdminService {
  Future<AdminDashboardStats> getDashboardStats();

  Stream<List<AdminOrder>> watchOrders();

  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus expectedStatus,
    required OrderStatus nextStatus,
    required String adminId,
  });

  Future<void> confirmPayment({
    required String orderId,
    required String adminId,
  });

  Future<String> createProduct({
    required String adminId,
    required AdminProductInput product,
  });

  Future<void> updateProduct({
    required String adminId,
    required String productId,
    required AdminProductInput product,
  });
}

class AdminServiceFailure implements Exception {
  const AdminServiceFailure(this.message);

  final String message;

  static String friendlyMessage(Object error) {
    if (error is AdminServiceFailure) return error.message;
    return 'The administrator service could not complete this request.';
  }

  @override
  String toString() => message;
}
