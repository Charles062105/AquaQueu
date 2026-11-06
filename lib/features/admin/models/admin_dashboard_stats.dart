import '../../../models/order.dart';

class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.completedOrders,
    required this.totalRecordedSales,
  });

  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int completedOrders;
  final int totalRecordedSales;

  // Recorded sales include only orders that are both Delivered and Paid.
  factory AdminDashboardStats.fromOrders(Iterable<Order> orders) {
    var totalOrders = 0;
    var pendingOrders = 0;
    var confirmedOrders = 0;
    var completedOrders = 0;
    var totalRecordedSales = 0;

    for (final order in orders) {
      totalOrders++;
      switch (order.status) {
        case OrderStatus.pending:
          pendingOrders++;
        case OrderStatus.confirmed:
          confirmedOrders++;
        case OrderStatus.delivered:
          completedOrders++;
        case OrderStatus.preparing:
        case OrderStatus.outForDelivery:
        case OrderStatus.cancelled:
          break;
      }
      if (order.status == OrderStatus.delivered &&
          order.paymentStatus == 'Paid') {
        totalRecordedSales += order.total;
      }
    }

    return AdminDashboardStats(
      totalOrders: totalOrders,
      pendingOrders: pendingOrders,
      confirmedOrders: confirmedOrders,
      completedOrders: completedOrders,
      totalRecordedSales: totalRecordedSales,
    );
  }
}
