import '../../../models/product.dart';

class AdminProductInput {
  const AdminProductInput({
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.available,
    this.imageUrl,
  });

  final String name;
  final String description;
  final int price;
  final ProductCategory category;
  final bool available;
  final String? imageUrl;

  static Map<String, String> validate({
    required String name,
    required String price,
    required String? imageUrl,
  }) {
    final errors = <String, String>{};
    if (name.trim().isEmpty) errors['name'] = 'Enter a product name.';
    if (name.trim().length > 120) {
      errors['name'] = 'Use 120 characters or fewer.';
    }
    final parsedPrice = int.tryParse(price.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      errors['price'] = 'Enter a price greater than zero.';
    }
    final trimmedUrl = imageUrl?.trim() ?? '';
    if (trimmedUrl.isNotEmpty) {
      final uri = Uri.tryParse(trimmedUrl);
      if (uri == null ||
          !uri.isAbsolute ||
          (uri.scheme != 'https' && uri.scheme != 'http') ||
          uri.host.isEmpty ||
          trimmedUrl.length > 2048) {
        errors['imageUrl'] = 'Enter a valid http or https image URL.';
      }
    }
    return errors;
  }
}
