import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/order.dart';
import '../../../services/order_service.dart';

class OrdersProvider extends ChangeNotifier {
  OrdersProvider({required this.orderService, required this.customerId}) {
    _subscribe();
  }

  final OrderService orderService;
  final String customerId;
  StreamSubscription<List<Order>>? _subscription;
  List<Order> _orders = const [];
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _subscribe() {
    _subscription = orderService
        .watchMyOrders(customerId)
        .listen(
          (orders) {
            if (_isDisposed) return;
            _orders = orders;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            if (_isDisposed) return;
            _isLoading = false;
            _errorMessage = OrderServiceFailure.friendlyMessage(error);
            notifyListeners();
          },
        );
  }

  Future<void> reload() async {
    if (_isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _orders = await orderService.getMyOrders(customerId);
    } catch (error) {
      _errorMessage = OrderServiceFailure.friendlyMessage(error);
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
