import '../../models/product.dart';

abstract final class MockProducts {
  // Illustrative sample products and prices only; no live inventory is used.
  static const all = [
    Product(
      id: 'purified-5-gallon',
      name: '5-Gallon Purified Water',
      description: 'Clean, refreshing purified water for your home or office.',
      price: 50,
      category: ProductCategory.purified,
    ),
    Product(
      id: 'mineral-5-gallon',
      name: '5-Gallon Mineral Water',
      description: 'Refreshing mineral water with a crisp, balanced taste.',
      price: 60,
      category: ProductCategory.mineral,
    ),
    Product(
      id: 'purified-1-gallon',
      name: '1-Gallon Purified Water',
      description: 'Convenient purified water for smaller households.',
      price: 25,
      category: ProductCategory.purified,
    ),
    Product(
      id: 'mineral-1-gallon-unavailable',
      name: '1-Gallon Mineral Water',
      description: 'Mineral water in a convenient one-gallon size.',
      price: 35,
      category: ProductCategory.mineral,
      available: false,
    ),
  ];

  static Product byId(String id) => all.firstWhere(
    (product) => product.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'Unknown product'),
  );
}

class MockProductsService {
  MockProductsService({
    this.delay = const Duration(milliseconds: 300),
    this.load,
  });

  final Duration delay;
  final Future<List<Product>> Function()? load;

  Future<List<Product>> loadProducts() async {
    await Future<void>.delayed(delay);
    final products = await (load?.call() ?? Future.value(MockProducts.all));
    return List<Product>.unmodifiable(products);
  }
}
