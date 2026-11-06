import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

abstract interface class ProductService {
  Future<List<Product>> getProducts();
}

class FirestoreProductService implements ProductService {
  FirestoreProductService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Product>> getProducts() async {
    final snapshot = await _firestore.collection('products').get();
    return List<Product>.unmodifiable(
      snapshot.docs.map((document) {
        final data = document.data();
        final name = _requiredString(data, 'name', document.id);
        final description = _requiredString(data, 'description', document.id);
        final categoryName = _requiredString(data, 'category', document.id);
        final price = data['price'];
        final available = data['available'];
        if (price is! num || available is! bool) {
          throw FormatException(
            'Product ${document.id} has an invalid price or availability.',
          );
        }
        final category = switch (categoryName.toLowerCase()) {
          'purified' => ProductCategory.purified,
          'mineral' => ProductCategory.mineral,
          _ => throw FormatException(
            'Product ${document.id} has an unsupported category.',
          ),
        };
        return Product(
          id: document.id,
          name: name,
          description: description,
          price: price.toInt(),
          category: category,
          available: available,
          imageUrl: data['imageUrl'] is String
              ? data['imageUrl'] as String
              : null,
        );
      }),
    );
  }

  static String _requiredString(
    Map<String, dynamic> data,
    String field,
    String productId,
  ) {
    final value = data[field];
    if (value is String) return value;
    throw FormatException('Product $productId is missing $field.');
  }
}
