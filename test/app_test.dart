import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_dependencies.dart';

void main() {
  testWidgets('application launches and shows AquaQueue', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expect(find.text('AquaQueue'), findsOneWidget);
  });

  testWidgets('unknown routes show the fallback page', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('AquaQueue'))).pushNamed('/missing');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
    expect(find.text('This page is unavailable.'), findsOneWidget);
  });
}
