import 'package:flutter_test/flutter_test.dart';

import 'package:aquaqueu/models/order.dart';

void main() {
  const allowedByType = {
    OrderDeliveryType.delivery: {
      OrderStatus.pending: [OrderStatus.confirmed, OrderStatus.cancelled],
      OrderStatus.confirmed: [OrderStatus.preparing, OrderStatus.cancelled],
      OrderStatus.preparing: [
        OrderStatus.outForDelivery,
        OrderStatus.cancelled,
      ],
      OrderStatus.outForDelivery: [
        OrderStatus.delivered,
        OrderStatus.cancelled,
      ],
      OrderStatus.delivered: <OrderStatus>[],
      OrderStatus.cancelled: <OrderStatus>[],
    },
    OrderDeliveryType.pickup: {
      OrderStatus.pending: [OrderStatus.confirmed, OrderStatus.cancelled],
      OrderStatus.confirmed: [OrderStatus.preparing, OrderStatus.cancelled],
      OrderStatus.preparing: [OrderStatus.delivered, OrderStatus.cancelled],
      OrderStatus.outForDelivery: <OrderStatus>[],
      OrderStatus.delivered: <OrderStatus>[],
      OrderStatus.cancelled: <OrderStatus>[],
    },
  };

  for (final deliveryType in OrderDeliveryType.values) {
    for (final from in OrderStatus.values) {
      for (final to in OrderStatus.values) {
        test(
          '${deliveryType.name}: ${from.label} -> ${to.label} is '
          '${allowedByType[deliveryType]![from]!.contains(to) ? 'allowed' : 'blocked'}',
          () {
            final expected = allowedByType[deliveryType]![from]!.contains(to);
            expect(canTransition(from, to, deliveryType), expected);
            expect(
              allowedNextStatuses(from, deliveryType).contains(to),
              expected,
            );
          },
        );
      }
    }
  }
}
