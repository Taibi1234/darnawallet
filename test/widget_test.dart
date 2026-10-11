
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:darnawallet/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DarnaWallet dashboard loads successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DarnaWalletApp());

    // Wait for local storage to load.
    await tester.pumpAndSettle();

    expect(find.text('DarnaWallet'), findsOneWidget);
    expect(find.text('MAD 12,450.00'), findsOneWidget);
    expect(find.text('Your overview'), findsOneWidget);
  });
}
