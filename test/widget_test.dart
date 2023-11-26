//import 'package:flutter/material.dart';
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
}
