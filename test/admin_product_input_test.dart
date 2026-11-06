import 'package:flutter_test/flutter_test.dart';

import 'package:aquaqueu/features/admin/models/admin_product_input.dart';

void main() {
  test(
    'product validation accepts a positive price and optional https URL',
    () {
      expect(
        AdminProductInput.validate(
          name: 'Purified Water',
          price: '50',
          imageUrl: 'https://example.com/water.jpg',
        ),
        isEmpty,
      );
      expect(
        AdminProductInput.validate(
          name: 'Purified Water',
          price: '50',
          imageUrl: '',
        ),
        isEmpty,
      );
    },
  );

  test('product validation rejects missing name, invalid price and URL', () {
    final errors = AdminProductInput.validate(
      name: ' ',
      price: '0',
      imageUrl: 'not-a-url',
    );

    expect(errors.keys, containsAll(['name', 'price', 'imageUrl']));
  });
}
