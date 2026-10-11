import 'dart:convert';

import 'package:darnawallet/main.dart';
import 'package:darnawallet/transaction_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Runs each test on a tall surface so every dashboard element and page
  // control is laid out and tappable without scrolling.
  void testWidgetsLarge(
    String description,
    Future<void> Function(WidgetTester) body,
  ) {
    testWidgets(description, (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await body(tester);
    });
  }

  testWidgetsLarge('DarnaWallet dashboard loads successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DarnaWalletApp());

    // Wait for local storage to load.
    await tester.pumpAndSettle();

    expect(find.text('DarnaWallet'), findsOneWidget);
    expect(find.text('MAD 12,450.00'), findsOneWidget);
    expect(find.text('Your overview'), findsOneWidget);
  });

  testWidgetsLarge('saved transactions are loaded from local storage', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      storageKey: jsonEncode([
        {
          'title': 'Saved rent',
          'category': 'Housing',
          'amount': -3000.0,
          'date': '2026-10-01T10:00:00.000',
        },
      ]),
    });

    await tester.pumpWidget(const DarnaWalletApp());
    await tester.pumpAndSettle();

    // The saved record replaces the demo data and drives the balance.
    expect(find.text('Saved rent'), findsOneWidget);
    expect(find.text('Grocery shopping'), findsNothing);
    expect(find.text('MAD 3,426.50'), findsOneWidget);
  });

  testWidgetsLarge('adding a transaction updates the dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DarnaWalletApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Test bonus');
    await tester.enterText(find.byType(TextFormField).at(1), '100.50');

    await tester.tap(find.text('Save transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction saved successfully.'), findsOneWidget);
    expect(find.text('Test bonus'), findsOneWidget);
    expect(find.text('MAD 12,349.50'), findsOneWidget);
  });

  group('TransactionManagementPage', () {
    List<Map<String, dynamic>> sampleTransactions() {
      return [
        {
          'title': 'Monthly salary',
          'category': 'Salary',
          'amount': 5000.0,
          'date': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Groceries',
          'category': 'Food & groceries',
          'amount': -200.0,
          'date': 'Today, 09:00 AM',
        },
        {
          'title': 'Old bill',
          'category': 'Utilities',
          'amount': -100.0,
          'date': '2020-01-15T00:00:00.000',
        },
      ];
    }

    Widget buildPage(List<Map<String, dynamic>> transactions) {
      return MaterialApp(
        home: Scaffold(
          body: TransactionManagementPage(
            transactions: transactions,
            onEdit: (_) async {},
            onDelete: (_) async {},
          ),
        ),
      );
    }

    testWidgetsLarge('shows filtered totals for all transactions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPage(sampleTransactions()));
      await tester.pumpAndSettle();

      expect(find.text('3 total transactions'), findsOneWidget);
      expect(find.text('3 found'), findsOneWidget);
      expect(find.text('+5,000.00'), findsOneWidget);
      expect(find.text('300.00'), findsOneWidget);
      expect(find.text('+4,700.00'), findsOneWidget);
    });

    testWidgetsLarge('search narrows the list and the summary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPage(sampleTransactions()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'gro');
      await tester.pump();

      expect(find.text('1 found'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Salary'), findsNothing);
      expect(find.text('Old bill'), findsNothing);
      expect(find.text('200.00'), findsOneWidget);
    });

    testWidgetsLarge('type filter separates income and expenses', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPage(sampleTransactions()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_downward));
      await tester.pump();

      expect(find.text('1 found'), findsOneWidget);
      expect(find.text('Monthly salary'), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();

      expect(find.text('2 found'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Old bill'), findsOneWidget);
      expect(find.text('Monthly salary'), findsNothing);
    });

    testWidgetsLarge('Today date filter keeps only current-day records', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildPage(sampleTransactions()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('All time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(find.text('2 found'), findsOneWidget);
      expect(find.text('Monthly salary'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Old bill'), findsNothing);
      expect(find.text('+4,800.00'), findsOneWidget);
    });

    testWidgetsLarge(
      'cancelling the custom range picker keeps all transactions',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildPage(sampleTransactions()));
        await tester.pumpAndSettle();

        await tester.tap(find.text('All time'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Custom date range'));
        await tester.pumpAndSettle();

        // Close the picker without choosing a range.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('3 found'), findsOneWidget);
        expect(find.text('Old bill'), findsOneWidget);
      },
    );
  });
}
