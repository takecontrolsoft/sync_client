import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sync_client/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('Login form', (WidgetTester tester) async {
      app.main();
      // await tester.pumpAndSettle();
      // expect(find.byKey(Key('username')), findsOneWidget);
      // expect(find.byKey(Key('password')), findsOneWidget);

      // await tester.tap(find.text("Login"));
      await tester.pump();
    });
  });
}
