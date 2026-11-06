import 'product.dart';

class OrderItem {
  const OrderItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get subtotal => product.price * quantity;
}
