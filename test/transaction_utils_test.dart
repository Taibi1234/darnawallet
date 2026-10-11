import 'package:darnawallet/transaction_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transactionAmount', () {
    test('reads numeric amounts as doubles', () {
      expect(transactionAmount({'amount': 5000}), 5000.0);
      expect(transactionAmount({'amount': -245.50}), -245.50);
    });

    test('parses string amounts', () {
      expect(transactionAmount({'amount': '199.00'}), 199.0);
    });

    test('treats missing or malformed amounts as zero', () {
      expect(transactionAmount({'amount': 'not-a-number'}), 0);
      expect(transactionAmount({}), 0);
    });
  });

  group('tryParseTransactionDate', () {
    final now = DateTime(2026, 10, 11, 20, 30);

    test('parses ISO-8601 values written by the app', () {
      final parsed = tryParseTransactionDate(
        '2026-09-05T14:45:00.000',
        now: now,
      );

      expect(parsed, DateTime(2026, 9, 5, 14, 45));
    });

    test('supports the legacy Today label', () {
      expect(
        tryParseTransactionDate('Today, 10:42 AM', now: now),
        DateTime(2026, 10, 11),
      );
      expect(
        tryParseTransactionDate('today', now: now),
        DateTime(2026, 10, 11),
      );
    });

    test('supports the legacy Yesterday label', () {
      expect(
        tryParseTransactionDate('Yesterday, 04:30 PM', now: now),
        DateTime(2026, 10, 10),
      );
    });

    test('supports the older Added label', () {
      expect(tryParseTransactionDate('Added just now', now: now), now);
    });

    test('returns null for malformed or empty values', () {
      expect(tryParseTransactionDate('not a date', now: now), isNull);
      expect(tryParseTransactionDate('', now: now), isNull);
      expect(tryParseTransactionDate(null, now: now), isNull);
    });
  });

  group('isInDateFilter', () {
    // 2026-10-14 is used as "today" for these tests.
    final now = DateTime(2026, 10, 14, 12, 0);
    final today = DateTime(2026, 10, 14);

    test('All time matches everything, even undated records', () {
      expect(isInDateFilter(today, 'All time', now: now), isTrue);
      expect(isInDateFilter(null, 'All time', now: now), isTrue);
    });

    test('malformed dates never match a period filter', () {
      expect(isInDateFilter(null, 'Today', now: now), isFalse);
      expect(isInDateFilter(null, 'This month', now: now), isFalse);
      expect(isInDateFilter(null, 'Custom range', now: now), isFalse);
    });

    test('Today only matches the current day', () {
      expect(isInDateFilter(today, 'Today', now: now), isTrue);
      expect(
        isInDateFilter(DateTime(2026, 10, 14, 23, 59), 'Today', now: now),
        isTrue,
      );
      expect(
        isInDateFilter(DateTime(2026, 10, 13), 'Today', now: now),
        isFalse,
      );
    });

    test('This week runs from Monday to today', () {
      final weekStart = today.subtract(Duration(days: today.weekday - 1));

      expect(isInDateFilter(weekStart, 'This week', now: now), isTrue);
      expect(isInDateFilter(today, 'This week', now: now), isTrue);
      expect(
        isInDateFilter(
          weekStart.subtract(const Duration(days: 1)),
          'This week',
          now: now,
        ),
        isFalse,
      );
      expect(
        isInDateFilter(
          today.add(const Duration(days: 1)),
          'This week',
          now: now,
        ),
        isFalse,
      );
    });

    test('This month matches the current calendar month', () {
      expect(
        isInDateFilter(DateTime(2026, 10, 1), 'This month', now: now),
        isTrue,
      );
      expect(
        isInDateFilter(DateTime(2026, 9, 30), 'This month', now: now),
        isFalse,
      );
    });

    test('Custom range is inclusive of both bounds', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 30);

      expect(
        isInDateFilter(
          DateTime(2026, 9, 1),
          'Custom range',
          rangeStart: start,
          rangeEnd: end,
          now: now,
        ),
        isTrue,
      );
      expect(
        isInDateFilter(
          DateTime(2026, 9, 30),
          'Custom range',
          rangeStart: start,
          rangeEnd: end,
          now: now,
        ),
        isTrue,
      );
      expect(
        isInDateFilter(
          DateTime(2026, 10, 1),
          'Custom range',
          rangeStart: start,
          rangeEnd: end,
          now: now,
        ),
        isFalse,
      );
    });

    test('Custom range without both bounds matches nothing', () {
      expect(isInDateFilter(today, 'Custom range', now: now), isFalse);
      expect(
        isInDateFilter(
          today,
          'Custom range',
          rangeStart: DateTime(2026, 1, 1),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('formatMoney', () {
    test('formats thousands with separators and two decimals', () {
      expect(formatMoney(12450.5), '12,450.50');
      expect(formatMoney(1000000), '1,000,000.00');
      expect(formatMoney(999.999), '1,000.00');
    });

    test('formats small amounts without separators', () {
      expect(formatMoney(0), '0.00');
      expect(formatMoney(32), '32.00');
    });

    test('never includes a sign', () {
      expect(formatMoney(-476.5), '476.50');
    });
  });

  group('totals', () {
    final transactions = <Map<String, dynamic>>[
      {'amount': 6500.0},
      {'amount': -245.5},
      {'amount': -32.0},
    ];

    test('income sums positive amounts only', () {
      expect(totalIncomeOf(transactions), 6500.0);
    });

    test('expenses sum the absolute value of negative amounts', () {
      expect(totalExpensesOf(transactions), 277.5);
    });

    test('empty lists total zero', () {
      expect(totalIncomeOf(const []), 0);
      expect(totalExpensesOf(const []), 0);
    });
  });
}
