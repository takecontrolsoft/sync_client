//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sync_client/main.dart';

void main() {
  testWidgets('Main menu test', (WidgetTester tester) async {
    await tester.pumpWidget(const BlocProviders());

    expect(find.text('Servers list'), findsOneWidget);
    expect(find.text('Folders list'), findsOneWidget);

    await tester.tap(find.text("Sync"));
    await tester.pump();
  });

  testWidgets('Theme change', (WidgetTester tester) async {
    await tester.pumpWidget(const BlocProviders());
    Finder themeButton =
        find.widgetWithIcon(IconButton, Icons.light_mode_outlined);

    expect(themeButton, findsOneWidget);
    await tester.tap(themeButton);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}
