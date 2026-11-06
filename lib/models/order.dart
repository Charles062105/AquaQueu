import 'order_item.dart';
import 'delivery_location.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled,
}

enum OrderDeliveryType { pickup, delivery }

String orderStatusValue(OrderStatus status) => switch (status) {
  OrderStatus.pending => 'Pending',
  OrderStatus.confirmed => 'Confirmed',
  OrderStatus.preparing => 'Preparing',
  OrderStatus.outForDelivery => 'Out for Delivery',
  OrderStatus.delivered => 'Delivered',
  OrderStatus.cancelled => 'Cancelled',
};

String orderStatusKey(OrderStatus status) => switch (status) {
  OrderStatus.pending => 'pending',
  OrderStatus.confirmed => 'confirmed',
  OrderStatus.preparing => 'preparing',
  OrderStatus.outForDelivery => 'out_for_delivery',
  OrderStatus.delivered => 'delivered',
  OrderStatus.cancelled => 'cancelled',
};

List<OrderStatus> allowedNextStatuses(
  OrderStatus from,
  OrderDeliveryType deliveryType,
) => switch (from) {
  OrderStatus.pending => [OrderStatus.confirmed, OrderStatus.cancelled],
  OrderStatus.confirmed => [OrderStatus.preparing, OrderStatus.cancelled],
  OrderStatus.preparing => [
    if (deliveryType == OrderDeliveryType.delivery)
      OrderStatus.outForDelivery
    else
      OrderStatus.delivered,
    OrderStatus.cancelled,
  ],
  OrderStatus.outForDelivery =>
    deliveryType == OrderDeliveryType.delivery
        ? [OrderStatus.delivered, OrderStatus.cancelled]
        : const [],
  OrderStatus.delivered || OrderStatus.cancelled => const [],
};

bool canTransition(
  OrderStatus from,
  OrderStatus to,
  OrderDeliveryType deliveryType,
) => allowedNextStatuses(from, deliveryType).contains(to);

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.preparing => 'Preparing',
    OrderStatus.outForDelivery => 'Out for Delivery',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };
}

class OrderStatusHistoryEntry {
  const OrderStatusHistoryEntry({
    required this.status,
    required this.changedBy,
    required this.changedAt,
  });

  final OrderStatus status;
  final String changedBy;
  final DateTime? changedAt;
}

class Order {
  const Order({
    required this.id,
    required this.date,
    required this.items,
    required this.status,
    required this.isDelivery,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.address,
    this.deliveryDate,
    this.deliveryTime,
    this.paymentStatus = 'Payment due',
    this.deliveryLocation,
  });

  final String id;
  final DateTime date;
  final List<OrderItem> items;
  final OrderStatus status;
  final bool isDelivery;
  final String paymentMethod;
  final String paymentStatus;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String? address;
  final String? deliveryDate;
  final String? deliveryTime;
  final DeliveryLocation? deliveryLocation;

  String? get deliveryAddress => address;
  String? get preferredDate => deliveryDate;
  String? get preferredTime => deliveryTime;

  String get productSummary {
    if (items.isEmpty) return 'No items';
    final first = items.first.product.name;
    final additionalCount = items.length - 1;
    return additionalCount > 0 ? '$first + $additionalCount more' : first;
  }
}
