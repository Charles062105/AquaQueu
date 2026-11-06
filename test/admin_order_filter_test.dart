import 'package:flutter_test/flutter_test.dart';

import 'package:aquaqueu/features/admin/models/admin_order.dart';
import 'package:aquaqueu/features/admin/presentation/admin_provider.dart';
import 'package:aquaqueu/models/order.dart';

AdminOrder _entry({
  required String id,
  required String customerName,
  required OrderStatus status,
}) {
  return AdminOrder(
    order: Order(
      id: id,
      date: DateTime(2026, 1, 1),
      items: const [],
      status: status,
      isDelivery: false,
      paymentMethod: 'Cash on Pickup',
      subtotal: 50,
      deliveryFee: 0,
      total: 50,
    ),
    customerId: 'customer-$id',
    customerName: customerName,
    customerEmail: '$customerName@example.com',
    customerPhone: '555-0100',
  );
}

void main() {
  test(
    'order search matches order number or customer name with status filter',
    () {
      final entries = [
        _entry(
          id: 'AQ-100',
          customerName: 'Alex Santos',
          status: OrderStatus.pending,
        ),
        _entry(
          id: 'AQ-200',
          customerName: 'Sam Lee',
          status: OrderStatus.confirmed,
        ),
      ];

      expect(
        AdminProvider.filterOrders(
          entries,
          query: 'alex',
        ).map((e) => e.order.id),
        ['AQ-100'],
      );
      expect(
        AdminProvider.filterOrders(
          entries,
          query: 'AQ-200',
        ).map((e) => e.order.id),
        ['AQ-200'],
      );
      expect(
        AdminProvider.filterOrders(
          entries,
          status: OrderStatus.pending,
        ).map((e) => e.order.id),
        ['AQ-100'],
      );
    },
  );
}
