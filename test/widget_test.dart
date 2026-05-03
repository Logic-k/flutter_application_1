import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MemoryLinkApp());
    await tester.pumpAndSettle(); // Wait for navigation

    // Verify that our app shows the initial navigation items.
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
  });
}
