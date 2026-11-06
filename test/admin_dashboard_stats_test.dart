import 'package:flutter_test/flutter_test.dart';

import 'package:aquaqueu/features/admin/models/admin_dashboard_stats.dart';
import 'package:aquaqueu/models/order.dart';

Order _order({
  required String id,
  required OrderStatus status,
  required String paymentStatus,
  required int total,
}) {
  return Order(
    id: id,
    date: DateTime(2026, 1, 1),
    items: const [],
    status: status,
    isDelivery: false,
    paymentMethod: 'Cash on Pickup',
    paymentStatus: paymentStatus,
    subtotal: total,
    deliveryFee: 0,
    total: total,
  );
}

void main() {
  test('dashboard totals count only Paid and Delivered sales', () {
    final stats = AdminDashboardStats.fromOrders([
      _order(
        id: 'pending',
        status: OrderStatus.pending,
        paymentStatus: 'Unpaid',
        total: 40,
      ),
      _order(
        id: 'confirmed',
        status: OrderStatus.confirmed,
        paymentStatus: 'Paid',
        total: 50,
      ),
      _order(
        id: 'delivered-paid',
        status: OrderStatus.delivered,
        paymentStatus: 'Paid',
        total: 100,
      ),
      _order(
        id: 'delivered-unpaid',
        status: OrderStatus.delivered,
        paymentStatus: 'Unpaid',
        total: 200,
      ),
      _order(
        id: 'cancelled-paid',
        status: OrderStatus.cancelled,
        paymentStatus: 'Paid',
        total: 300,
      ),
      _order(
        id: 'incomplete-paid',
        status: OrderStatus.preparing,
        paymentStatus: 'Paid',
        total: 400,
      ),
    ]);

    expect(stats.totalOrders, 6);
    expect(stats.pendingOrders, 1);
    expect(stats.confirmedOrders, 1);
    expect(stats.completedOrders, 2);
    expect(stats.totalRecordedSales, 100);
  });
}
