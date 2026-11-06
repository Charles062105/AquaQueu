import 'package:flutter/foundation.dart';

import '../../../models/product.dart';
import '../../../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider(this._service) {
    loadProducts();
  }

  final ProductService _service;
  int _request = 0;

  List<Product> _products = const [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProducts() async {
    if (_isDisposed) return;
    final request = ++_request;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final products = await _service.getProducts();
      if (!_isDisposed && request == _request) _products = products;
    } catch (error) {
      if (!_isDisposed && request == _request) {
        _errorMessage = 'Products could not be loaded. Check your connection and try again.';
      }
    } finally {
      if (!_isDisposed && request == _request) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _request++;
    super.dispose();
  }
}
