import '../../../models/order.dart';

class AdminOrder {
  const AdminOrder({
    required this.order,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  final Order order;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
}
