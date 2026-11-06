import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aquaqueu/features/orders/presentation/widgets/order_status_timeline.dart';
import 'package:aquaqueu/models/order.dart';

Order _order({required bool isDelivery, required OrderStatus status}) {
  return Order(
    id: 'AQ-TIMELINE-001',
    date: DateTime(2026, 11, 6, 9),
    items: const [],
    status: status,
    isDelivery: isDelivery,
    paymentMethod: isDelivery ? 'Cash on Delivery' : 'Cash on Pickup',
    paymentStatus: 'Unpaid',
    subtotal: 100,
    deliveryFee: isDelivery ? 30 : 0,
    total: isDelivery ? 130 : 100,
  );
}

void main() {
  testWidgets('pickup timeline skips Out for Delivery and shows timestamps', (
    tester,
  ) async {
    final order = _order(isDelivery: false, status: OrderStatus.preparing);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderStatusTimeline(
            order: order,
            history: [
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
            ],
          ),
        ),
      ),
    );

    expect(find.text('Out for Delivery'), findsNothing);
    expect(find.text('Preparing'), findsOneWidget);
    expect(find.textContaining('09:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivery timeline includes Out for Delivery', (tester) async {
    final order = _order(isDelivery: true, status: OrderStatus.outForDelivery);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderStatusTimeline(
            order: order,
            history: const [
              OrderStatusHistoryEntry(
                status: OrderStatus.outForDelivery,
                changedBy: 'admin-1',
                changedAt: null,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Out for Delivery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled timeline shows a friendly final-state notice', (
    tester,
  ) async {
    final order = _order(isDelivery: false, status: OrderStatus.cancelled);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderStatusTimeline(
            order: order,
            history: const [
              OrderStatusHistoryEntry(
                status: OrderStatus.cancelled,
                changedBy: 'admin-1',
                changedAt: null,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('This order was cancelled by the shop.'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });
}
