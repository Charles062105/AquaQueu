import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../core/constants/app_constants.dart';
import '../models/delivery_location.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/product.dart';
import 'order_service.dart';

class FirestoreOrderService implements OrderService {
  FirestoreOrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  @override
  String generateOrderId() {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final autoId = _orders.doc().id;
    return 'AQ-$date-$autoId';
  }

  @override
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
  }) async {
    _validateRequest(
      quantities: quantities,
      isDelivery: isDelivery,
      deliveryAddress: deliveryAddress,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      deliveryLocation: deliveryLocation,
    );

    final orderReference = _orders.doc(orderId);
    try {
      return await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(orderReference);
        if (existing.exists) {
          final data = existing.data()!;
          if (_matchesRequest(
            data: data,
            customerId: customerId,
            orderId: orderId,
            quantities: quantities,
            isDelivery: isDelivery,
            deliveryAddress: deliveryAddress,
            preferredDate: preferredDate,
            preferredTime: preferredTime,
            deliveryLocation: deliveryLocation,
          )) {
            return orderFromData(existing.id, data);
          }
          throw const OrderServiceFailure(
            'This order attempt already exists with different details. '
            'Please review your cart and try again.',
          );
        }

        final productSnapshots =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final productId in quantities.keys) {
          final reference = _firestore.collection('products').doc(productId);
          productSnapshots[productId] = await transaction.get(reference);
        }

        final items = <Map<String, dynamic>>[];
        final orderItems = <OrderItem>[];
        var subtotal = 0;
        for (final entry in quantities.entries) {
          final snapshot = productSnapshots[entry.key]!;
          if (!snapshot.exists) {
            throw OrderValidationFailure(
              'A product in your cart is no longer available. '
              'Remove it and review your cart.',
            );
          }
          final data = snapshot.data()!;
          final productName = data['name'];
          final rawPrice = data['price'];
          final available = data['available'];
          if (productName is! String ||
              rawPrice is! num ||
              available is! bool) {
            throw const OrderValidationFailure(
              'A product in your cart has invalid catalog information. '
              'Refresh the catalog and try again.',
            );
          }
          if (!available) {
            throw OrderValidationFailure(
              '$productName is no longer available. Remove it from your cart '
              'before placing the order.',
            );
          }
          if (rawPrice != rawPrice.toInt()) {
            throw OrderValidationFailure(
              '$productName has an unsupported price. Please contact the shop.',
            );
          }
          final unitPrice = rawPrice.toInt();
          if (displayedPrices[entry.key] != unitPrice) {
            throw OrderValidationFailure(
              'The price of $productName has changed. The catalog is being '
              'refreshed; please review the updated cart total.',
            );
          }

          final lineTotal = unitPrice * entry.value;
          subtotal += lineTotal;
          items.add({
            'productId': entry.key,
            'productName': productName,
            'unitPrice': unitPrice,
            'quantity': entry.value,
            'lineTotal': lineTotal,
          });
          orderItems.add(
            OrderItem(
              product: Product(
                id: entry.key,
                name: productName,
                description: '',
                price: unitPrice,
                category: ProductCategory.purified,
              ),
              quantity: entry.value,
            ),
          );
        }

        final deliveryFee = isDelivery ? AppConstants.deliveryFee : 0;
        final totalAmount = subtotal + deliveryFee;
        final paymentMethod = isDelivery
            ? 'Cash on Delivery'
            : 'Cash on Pickup';
        final preferredDateString = isDelivery
            ? _dateString(preferredDate!)
            : null;
        final orderNumber = orderId;
        final orderData = <String, dynamic>{
          'orderNumber': orderNumber,
          'customerId': customerId,
          'items': items,
          'deliveryType': isDelivery ? 'delivery' : 'pickup',
          'deliveryAddress': isDelivery ? deliveryAddress!.trim() : null,
          'preferredDate': preferredDateString,
          'preferredTime': isDelivery ? preferredTime : null,
          'subtotal': subtotal,
          'deliveryFee': deliveryFee,
          'totalAmount': totalAmount,
          'paymentMethod': paymentMethod,
          'paymentStatus': 'Unpaid',
          'orderStatus': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
          if (isDelivery && deliveryLocation != null)
            'deliveryLocation': GeoPoint(
              deliveryLocation.latitude,
              deliveryLocation.longitude,
            ),
        };
        transaction.set(orderReference, orderData);

        return Order(
          id: orderNumber,
          date: DateTime.now(),
          items: List.unmodifiable(orderItems),
          status: OrderStatus.pending,
          isDelivery: isDelivery,
          paymentMethod: paymentMethod,
          paymentStatus: 'Unpaid',
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          total: totalAmount,
          address: isDelivery ? deliveryAddress!.trim() : null,
          deliveryDate: preferredDateString,
          deliveryTime: isDelivery ? preferredTime : null,
          deliveryLocation: isDelivery ? deliveryLocation : null,
        );
      });
    } on OrderServiceFailure {
      rethrow;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        final catalogConflict = await _catalogConflict(
          quantities: quantities,
          displayedPrices: displayedPrices,
        );
        if (catalogConflict != null) throw catalogConflict;
      }
      throw OrderServiceFailure(_friendlyFirestoreMessage(error.code));
    }
  }

  @override
  Stream<List<Order>> watchMyOrders(String customerId) {
    return _orders
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => List<Order>.unmodifiable(
            snapshot.docs.map(
              (document) => orderFromData(document.id, document.data()),
            ),
          ),
        )
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw OrderServiceFailure(_friendlyFirestoreMessage(error.code));
          }
          throw error;
        });
  }

  @override
  Future<List<Order>> getMyOrders(String customerId) async {
    try {
      final snapshot = await _orders
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      return List<Order>.unmodifiable(
        snapshot.docs.map(
          (document) => orderFromData(document.id, document.data()),
        ),
      );
    } on FirebaseException catch (error) {
      throw OrderServiceFailure(_friendlyFirestoreMessage(error.code));
    }
  }

  @override
  Stream<Order> watchOrder(String orderId) {
    return _orders
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw const OrderServiceFailure(
              'This order is no longer available.',
            );
          }
          return orderFromData(snapshot.id, snapshot.data()!);
        })
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw OrderServiceFailure(_friendlyFirestoreMessage(error.code));
          }
          throw error;
        });
  }

  @override
  Stream<List<OrderStatusHistoryEntry>> watchStatusHistory(String orderId) {
    return _orders
        .doc(orderId)
        .collection('statusHistory')
        .orderBy('changedAt')
        .snapshots()
        .map(
          (snapshot) => List<OrderStatusHistoryEntry>.unmodifiable(
            snapshot.docs.map((document) {
              final data = document.data();
              final status = _statusFromValue(data['status']);
              final changedBy = data['changedBy'];
              final changedAt = data['changedAt'];
              if (changedBy is! String) {
                throw const FormatException(
                  'This order has invalid status history.',
                );
              }
              return OrderStatusHistoryEntry(
                status: status,
                changedBy: changedBy,
                changedAt: changedAt is Timestamp ? changedAt.toDate() : null,
              );
            }),
          ),
        )
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw OrderServiceFailure(_friendlyFirestoreMessage(error.code));
          }
          throw error;
        });
  }

  static void _validateRequest({
    required Map<String, int> quantities,
    required bool isDelivery,
    required String? deliveryAddress,
    required DateTime? preferredDate,
    required String? preferredTime,
    required DeliveryLocation? deliveryLocation,
  }) {
    if (quantities.isEmpty) {
      throw const OrderValidationFailure(
        'Your cart is empty. Add a product before placing an order.',
      );
    }
    if (quantities.length > 3) {
      throw const OrderValidationFailure(
        'An order can include up to three different products.',
      );
    }
    if (quantities.values.any((quantity) => quantity < 1 || quantity > 99)) {
      throw const OrderValidationFailure(
        'Product quantities must be between 1 and 99.',
      );
    }
    if (isDelivery) {
      if (deliveryAddress == null || deliveryAddress.trim().isEmpty) {
        throw const OrderValidationFailure(
          'Enter a complete delivery address.',
        );
      }
      if (preferredDate == null || _isBeforeToday(preferredDate)) {
        throw const OrderValidationFailure(
          'Choose a delivery date that is not in the past.',
        );
      }
      if (preferredTime == null || preferredTime.trim().isEmpty) {
        throw const OrderValidationFailure('Choose a preferred delivery time.');
      }
      if (deliveryLocation != null && !deliveryLocation.isValid) {
        throw const OrderValidationFailure(
          'Choose a valid delivery location on the map.',
        );
      }
    } else if (deliveryLocation != null) {
      throw const OrderValidationFailure(
        'Pickup orders cannot include a delivery location.',
      );
    }
  }

  static bool _isBeforeToday(DateTime date) {
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  Future<OrderValidationFailure?> _catalogConflict({
    required Map<String, int> quantities,
    required Map<String, int> displayedPrices,
  }) async {
    try {
      for (final productId in quantities.keys) {
        final snapshot = await _firestore
            .collection('products')
            .doc(productId)
            .get();
        final data = snapshot.data();
        if (!snapshot.exists || data == null || data['available'] != true) {
          return const OrderValidationFailure(
            'A product in your cart is no longer available. '
            'Review your cart before trying again.',
          );
        }
        final productName = data['name'];
        final currentPrice = data['price'];
        if (productName is String &&
            currentPrice is num &&
            displayedPrices[productId] != currentPrice.toInt()) {
          return OrderValidationFailure(
            'The price of $productName has changed. '
            'Review the updated cart total before trying again.',
          );
        }
      }
    } on FirebaseException {
      return null;
    }
    return null;
  }

  static String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static bool _matchesRequest({
    required Map<String, dynamic> data,
    required String customerId,
    required String orderId,
    required Map<String, int> quantities,
    required bool isDelivery,
    required String? deliveryAddress,
    required DateTime? preferredDate,
    required String? preferredTime,
    required DeliveryLocation? deliveryLocation,
  }) {
    final items = data['items'];
    if (data['customerId'] != customerId ||
        data['orderNumber'] != orderId ||
        data['deliveryType'] != (isDelivery ? 'delivery' : 'pickup') ||
        data['deliveryAddress'] !=
            (isDelivery ? deliveryAddress?.trim() : null) ||
        data['preferredDate'] !=
            (isDelivery && preferredDate != null
                ? _dateString(preferredDate)
                : null) ||
        data['preferredTime'] != (isDelivery ? preferredTime : null) ||
        !_matchesLocation(
          data,
          isDelivery ? deliveryLocation : null,
        ) ||
        data['paymentMethod'] !=
            (isDelivery ? 'Cash on Delivery' : 'Cash on Pickup') ||
        items is! List ||
        items.length != quantities.length) {
      return false;
    }
    for (final item in items) {
      if (item is! Map<String, dynamic> ||
          quantities[item['productId']] != item['quantity']) {
        return false;
      }
    }
    return true;
  }

  static bool _matchesLocation(
    Map<String, dynamic> data,
    DeliveryLocation? location,
  ) {
    final stored = data['deliveryLocation'];
    if (location == null) return !data.containsKey('deliveryLocation');
    return stored is GeoPoint &&
        stored.latitude == location.latitude &&
        stored.longitude == location.longitude;
  }

  static Order orderFromData(String documentId, Map<String, dynamic> data) {
    final rawItems = data['items'];
    final createdAt = data['createdAt'];
    if (rawItems is! List || createdAt is! Timestamp) {
      throw const FormatException('This order has invalid stored data.');
    }
    final items = <OrderItem>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map<String, dynamic>) {
        throw const FormatException('This order contains an invalid item.');
      }
      final productId = rawItem['productId'];
      final productName = rawItem['productName'];
      final unitPrice = rawItem['unitPrice'];
      final quantity = rawItem['quantity'];
      final lineTotal = rawItem['lineTotal'];
      if (productId is! String ||
          productName is! String ||
          unitPrice is! num ||
          quantity is! int ||
          lineTotal != unitPrice * quantity) {
        throw const FormatException('This order contains an invalid item.');
      }
      items.add(
        OrderItem(
          product: Product(
            id: productId,
            name: productName,
            description: '',
            price: unitPrice.toInt(),
            category: ProductCategory.purified,
          ),
          quantity: quantity,
        ),
      );
    }

    final orderNumber = data['orderNumber'];
    final deliveryType = data['deliveryType'];
    final subtotal = data['subtotal'];
    final deliveryFee = data['deliveryFee'];
    final totalAmount = data['totalAmount'];
    final paymentMethod = data['paymentMethod'];
    final paymentStatus = data['paymentStatus'];
    final orderStatus = data['orderStatus'];
    if (orderNumber is! String ||
        deliveryType is! String ||
        subtotal is! num ||
        deliveryFee is! num ||
        totalAmount is! num ||
        paymentMethod is! String ||
        paymentStatus is! String ||
        orderStatus is! String) {
      throw const FormatException('This order has invalid stored data.');
    }
    final status = _statusFromValue(orderStatus);
    final isDelivery = deliveryType == 'delivery';
    return Order(
      id: orderNumber,
      date: createdAt.toDate(),
      items: List.unmodifiable(items),
      status: status,
      isDelivery: isDelivery,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      subtotal: subtotal.toInt(),
      deliveryFee: deliveryFee.toInt(),
      total: totalAmount.toInt(),
      address: data['deliveryAddress'] as String?,
      deliveryDate: data['preferredDate'] as String?,
      deliveryTime: data['preferredTime'] as String?,
      deliveryLocation: _locationFromData(data['deliveryLocation']),
    );
  }

  static DeliveryLocation? _locationFromData(Object? value) {
    if (value == null) return null;
    if (value is! GeoPoint) {
      throw const FormatException(
        'This order has an invalid delivery location.',
      );
    }
    final location = DeliveryLocation(
      latitude: value.latitude,
      longitude: value.longitude,
    );
    if (!location.isValid) {
      throw const FormatException(
        'This order has an invalid delivery location.',
      );
    }
    return location;
  }

  static OrderStatus _statusFromValue(Object? value) => switch (value) {
    'Pending' => OrderStatus.pending,
    'Confirmed' => OrderStatus.confirmed,
    'Preparing' => OrderStatus.preparing,
    'Out for Delivery' => OrderStatus.outForDelivery,
    'Delivered' => OrderStatus.delivered,
    'Cancelled' => OrderStatus.cancelled,
    _ => throw const FormatException('This order has an unknown status.'),
  };

  static String _friendlyFirestoreMessage(String code) => switch (code) {
    'permission-denied' =>
      'AquaQueue could not save this order. Check that you are signed in, '
          'then try again.',
    'unavailable' || 'deadline-exceeded' =>
      'The order service is temporarily unavailable. Your cart is still here; '
          'check your connection and try again.',
    'failed-precondition' =>
      'The order service is not ready yet. Please try again later.',
    _ => 'The order could not be submitted. Your cart is still here; please try again.',
  };
}
