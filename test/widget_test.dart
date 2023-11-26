//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sync_client/main.dart';
import 'package:sync_client/service_locator.dart';

void main() {
  setUp(() {
    serviceLocatorInit();
  });
  testWidgets('Main menu test', (WidgetTester tester) async {
    await tester.pumpWidget(const BlocProviders());

    expect(find.text('Servers list'), findsOneWidget);
    expect(find.text('Folders list'), findsOneWidget);

    await tester.tap(find.text("Sync"));
    await tester.pump();
  });

  testWidgets('Theme change', (WidgetTester tester) async {
    await tester.pumpWidget(const BlocProviders());
    final Finder themeButton =
        find.widgetWithIcon(IconButton, Icons.light_mode_outlined);

    expect(themeButton, findsOneWidget);
    await tester.tap(themeButton);
    await tester.pump();
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    // expect(
    //   Theme.of(tester.element(find.text('Servers list'))).brightness,
    //   equals(Brightness.dark),
    //   reason:
    //       "Since MaterialApp() was set to dark theme when it was built at tester.pumpWidget(), the MaterialApp should be in dark theme",
    // );
    await tester.pump();
  });
}
