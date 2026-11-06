enum ProductCategory { purified, mineral }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.available = true,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final ProductCategory category;
  final bool available;
  final String? imageUrl;

  String get categoryLabel => switch (category) {
    ProductCategory.purified => 'Purified',
    ProductCategory.mineral => 'Mineral',
  };

  Product copyWith({
    String? name,
    String? description,
    int? price,
    ProductCategory? category,
    bool? available,
    String? imageUrl,
    bool clearImageUrl = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      available: available ?? this.available,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
    );
  }
}
