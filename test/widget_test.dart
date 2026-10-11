import 'package:flutter_test/flutter_test.dart';
import 'package:darnawallet/main.dart';

void main() {
  testWidgets('DarnaWallet dashboard loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const DarnaWalletApp());
    await tester.pumpAndSettle();

    expect(find.text('DarnaWallet'), findsWidgets);
    expect(find.text('MAD 12,450.00'), findsOneWidget);
  });
}

