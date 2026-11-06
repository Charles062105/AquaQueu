import '../models/order.dart';
import '../models/delivery_location.dart';

abstract interface class OrderService {
  String generateOrderId();

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
  });

  Stream<List<Order>> watchMyOrders(String customerId);

  Future<List<Order>> getMyOrders(String customerId);

  Stream<Order> watchOrder(String orderId);

  Stream<List<OrderStatusHistoryEntry>> watchStatusHistory(String orderId);
}

class OrderServiceFailure implements Exception {
  const OrderServiceFailure(this.message);

  final String message;

  static String friendlyMessage(Object error) {
    if (error is OrderServiceFailure) return error.message;
    return 'Orders could not be loaded. Check your connection and try again.';
  }

  @override
  String toString() => message;
}

class OrderValidationFailure extends OrderServiceFailure {
  const OrderValidationFailure(super.message);
}
