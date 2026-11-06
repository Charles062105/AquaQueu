import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../features/admin/models/admin_dashboard_stats.dart';
import '../features/admin/models/admin_order.dart';
import '../features/admin/models/admin_product_input.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import 'admin_service.dart';
import 'firestore_order_service.dart';

class FirestoreAdminService implements AdminService {
  FirestoreAdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _actions =>
      _firestore.collection('adminActions');

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      final deliveredAndPaid = _orders
          .where('orderStatus', isEqualTo: 'Delivered')
          .where('paymentStatus', isEqualTo: 'Paid');
      final results = await Future.wait<AggregateQuerySnapshot>([
        _orders.aggregate(count()).get(),
        _orders
            .where('orderStatus', isEqualTo: 'Pending')
            .aggregate(count())
            .get(),
        _orders
            .where('orderStatus', isEqualTo: 'Confirmed')
            .aggregate(count())
            .get(),
        _orders
            .where('orderStatus', isEqualTo: 'Delivered')
            .aggregate(count())
            .get(),
        deliveredAndPaid.aggregate(sum('totalAmount')).get(),
      ]);
      return AdminDashboardStats(
        totalOrders: results[0].count ?? 0,
        pendingOrders: results[1].count ?? 0,
        confirmedOrders: results[2].count ?? 0,
        completedOrders: results[3].count ?? 0,
        totalRecordedSales: (results[4].getSum('totalAmount') ?? 0).round(),
      );
    } on FirebaseException catch (error) {
      throw AdminServiceFailure(_friendlyFirestoreMessage(error.code));
    }
  }

  @override
  Stream<List<AdminOrder>> watchOrders() {
    return _orders.orderBy('createdAt', descending: true).snapshots().asyncMap((
      snapshot,
    ) async {
      try {
        final documents = snapshot.docs;
        final customerIds = documents
            .map((document) => document.data()['customerId'])
            .whereType<String>()
            .toSet()
            .toList();
        final customerProfiles = await _loadCustomers(customerIds);

        return List<AdminOrder>.unmodifiable(
          documents.map((document) {
            final data = document.data();
            final customerId = data['customerId'];
            if (customerId is! String) {
              throw const FormatException(
                'An order is missing its customer identifier.',
              );
            }
            final customer = customerProfiles[customerId];
            return AdminOrder(
              order: FirestoreOrderService.orderFromData(document.id, data),
              customerId: customerId,
              customerName: customer?.fullName ?? 'Unknown customer',
              customerEmail: customer?.email ?? '',
              customerPhone: customer?.phoneNumber ?? '',
            );
          }),
        );
      } on FirebaseException catch (error) {
        throw AdminServiceFailure(_friendlyFirestoreMessage(error.code));
      }
    });
  }

  Future<Map<String, AppUser>> _loadCustomers(List<String> customerIds) async {
    final users = <String, AppUser>{};
    for (var start = 0; start < customerIds.length; start += 30) {
      final end = (start + 30).clamp(0, customerIds.length);
      final snapshot = await _users
          .where(FieldPath.documentId, whereIn: customerIds.sublist(start, end))
          .get();
      for (final document in snapshot.docs) {
        final data = document.data();
        users[document.id] = AppUser(
          uid: document.id,
          fullName: _stringOrEmpty(data['fullName']),
          email: _stringOrEmpty(data['email']),
          phoneNumber: _stringOrEmpty(data['phoneNumber']),
          address: _stringOrEmpty(data['address']),
          role: data['role'] == 'admin' ? 'admin' : 'customer',
        );
      }
    }
    return users;
  }

  @override
  Future<void> confirmPayment({
    required String orderId,
    required String adminId,
  }) async {
    final order = _orders.doc(orderId);
    final action = _actions.doc();
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(order);
        if (!snapshot.exists || snapshot.data()?['paymentStatus'] != 'Unpaid') {
          throw const AdminServiceFailure(
            'Only unpaid orders can be marked as paid.',
          );
        }
        transaction.update(order, {
          'paymentStatus': 'Paid',
          'paidAt': FieldValue.serverTimestamp(),
        });
        transaction.set(
          action,
          _actionData(
            adminId: adminId,
            action: 'payment_confirmed',
            targetId: orderId,
          ),
        );
      });
    } on FirebaseException catch (error) {
      throw AdminServiceFailure(_friendlyFirestoreMessage(error.code));
    }
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus expectedStatus,
    required OrderStatus nextStatus,
    required String adminId,
  }) async {
    final order = _orders.doc(orderId);
    final history = order
        .collection('statusHistory')
        .doc(orderStatusKey(nextStatus));
    final action = _actions.doc(
      'status-$orderId-${orderStatusKey(nextStatus)}',
    );
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(order);
        if (!snapshot.exists) {
          throw const AdminServiceFailure('This order no longer exists.');
        }
        final data = snapshot.data()!;
        final currentStatus = _statusFromValue(data['orderStatus']);
        if (currentStatus != expectedStatus) {
          throw const AdminServiceFailure(
            'This order status changed while you were viewing it. '
            'The order list is refreshing; reopen the order and try again.',
          );
        }
        final deliveryType = data['deliveryType'];
        if (deliveryType != 'pickup' && deliveryType != 'delivery') {
          throw const AdminServiceFailure(
            'This order has an invalid delivery type and cannot be updated.',
          );
        }
        final type = deliveryType == 'delivery'
            ? OrderDeliveryType.delivery
            : OrderDeliveryType.pickup;
        if (!canTransition(currentStatus, nextStatus, type)) {
          throw const AdminServiceFailure(
            'That status change is not allowed for this order.',
          );
        }

        final historySnapshot = await transaction.get(history);
        final actionSnapshot = await transaction.get(action);
        if (historySnapshot.exists || actionSnapshot.exists) {
          throw const AdminServiceFailure(
            'This status update was already recorded. Refresh the order.',
          );
        }

        final update = <String, Object>{
          'orderStatus': orderStatusValue(nextStatus),
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        };
        if (nextStatus == OrderStatus.confirmed) {
          update['confirmedAt'] = FieldValue.serverTimestamp();
        }
        transaction.update(order, update);
        transaction.set(history, {
          'status': orderStatusValue(nextStatus),
          'changedAt': FieldValue.serverTimestamp(),
          'changedBy': adminId,
        });
        transaction.set(
          action,
          _actionData(
            adminId: adminId,
            action: 'order_status_changed',
            targetId: orderId,
          )..['status'] = orderStatusValue(nextStatus),
        );
      });
    } on AdminServiceFailure {
      rethrow;
    } on FirebaseException catch (error) {
      throw AdminServiceFailure(_friendlyFirestoreMessage(error.code));
    }
  }

  @override
  Future<String> createProduct({
    required String adminId,
    required AdminProductInput product,
  }) async {
    _validateProduct(product);
    final reference = _products.doc();
    final batch = _firestore.batch();
    batch.set(reference, {
      ..._productData(product),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _addAction(
      batch,
      adminId: adminId,
      action: 'product_created',
      targetId: reference.id,
    );
    try {
      await batch.commit();
      return reference.id;
    } on FirebaseException catch (error) {
      throw AdminServiceFailure(_friendlyFirestoreMessage(error.code));
    }
  }

  @override
  Future<void> updateProduct({
    required String adminId,
    required String productId,
    required AdminProductInput product,
  }) async {
    _validateProduct(product);
    final reference = _products.doc(productId);
    final batch = _firestore.batch();
    batch.update(reference, {
      ..._productData(product),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _addAction(
      batch,
      adminId: adminId,
      action: 'product_edited',
      targetId: productId,
    );
    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      throw AdminServiceFailure(_friendlyFirestoreMessage(error.code));
    }
  }

  static void _validateProduct(AdminProductInput product) {
    final errors = AdminProductInput.validate(
      name: product.name,
      price: product.price.toString(),
      imageUrl: product.imageUrl,
    );
    if (errors.isNotEmpty) {
      throw AdminServiceFailure(errors.values.first);
    }
    if (product.description.trim().length > 2000) {
      throw const AdminServiceFailure(
        'Product descriptions must be 2000 characters or fewer.',
      );
    }
  }

  static Map<String, dynamic> _productData(AdminProductInput product) => {
    'name': product.name.trim(),
    'description': product.description.trim(),
    'price': product.price,
    'category': product.category.name,
    'available': product.available,
    'imageUrl': product.imageUrl?.trim().isEmpty == true
        ? null
        : product.imageUrl?.trim(),
  };

  void _addAction(
    WriteBatch batch, {
    required String adminId,
    required String action,
    required String targetId,
  }) {
    batch.set(
      _actions.doc(),
      _actionData(adminId: adminId, action: action, targetId: targetId),
    );
  }

  static Map<String, dynamic> _actionData({
    required String adminId,
    required String action,
    required String targetId,
  }) => {
    'adminId': adminId,
    'action': action,
    'targetId': targetId,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static String _stringOrEmpty(Object? value) => value is String ? value : '';

  static OrderStatus _statusFromValue(Object? value) => switch (value) {
    'Pending' => OrderStatus.pending,
    'Confirmed' => OrderStatus.confirmed,
    'Preparing' => OrderStatus.preparing,
    'Out for Delivery' => OrderStatus.outForDelivery,
    'Delivered' => OrderStatus.delivered,
    'Cancelled' => OrderStatus.cancelled,
    _ => throw const AdminServiceFailure(
      'This order has an invalid status and cannot be updated.',
    ),
  };

  static String _friendlyFirestoreMessage(String code) => switch (code) {
    'permission-denied' =>
      'This action is restricted to administrator accounts.',
    'unavailable' || 'deadline-exceeded' => 'The administrator service is temporarily unavailable. Try again shortly.',
    'not-found' => 'The selected record no longer exists.',
    _ => 'The administrator request could not be completed. Please try again.',
  };
}
