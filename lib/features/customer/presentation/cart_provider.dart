import 'package:flutter/foundation.dart';

import '../../../models/product.dart';

class CartProvider extends ChangeNotifier {
  static const maximumDistinctProducts = 3;

  final Map<String, int> _quantities = {};

  Map<String, int> get quantities => Map.unmodifiable(_quantities);
  int get itemCount =>
      _quantities.values.fold(0, (total, value) => total + value);
  bool get isEmpty => _quantities.isEmpty;

  bool addProduct(Product product, {int quantity = 1}) {
    if (!product.available || quantity < 1 || quantity > 99) return false;
    if (!_quantities.containsKey(product.id) &&
        _quantities.length >= maximumDistinctProducts) {
      return false;
    }
    final updatedQuantity = (_quantities[product.id] ?? 0) + quantity;
    if (updatedQuantity > 99) return false;
    _quantities[product.id] = updatedQuantity;
    notifyListeners();
    return true;
  }

  bool setQuantity(String productId, int quantity) {
    if (quantity < 1 || quantity > 99 || !_quantities.containsKey(productId)) {
      return false;
    }
    _quantities[productId] = quantity;
    notifyListeners();
    return true;
  }

  void removeProduct(String productId) {
    if (_quantities.remove(productId) != null) notifyListeners();
  }

  void clear() {
    if (_quantities.isEmpty) return;
    _quantities.clear();
    notifyListeners();
  }
}
