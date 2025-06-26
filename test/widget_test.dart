import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bambooapp/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify app contains title
    expect(find.text('Bamboo Classifier'), findsOneWidget);

    // Optionally test for button or widget existence
    expect(find.byIcon(Icons.image), findsOneWidget);
  });
}
