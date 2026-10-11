/// Shared helpers for reading wallet transactions.
///
/// Transactions are stored as `Map<String, dynamic>` with the keys
/// `title`, `category`, `amount` and `date`. These helpers centralize the
/// tolerant parsing of those values so every screen behaves the same way.
library;

/// Extracts the numeric amount from a transaction.
///
/// Negative values are expenses, positive values are income.
/// Unparseable amounts count as zero instead of crashing the app.
double transactionAmount(Map<String, dynamic> transaction) {
  final raw = transaction['amount'];

  if (raw is num) {
    return raw.toDouble();
  }

  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

/// Parses the stored date of a transaction.
///
/// Supported values:
/// - ISO-8601 strings written by the app (e.g. `2026-10-11T20:52:17.000`).
/// - Legacy demo labels such as `Today, 10:42 AM`, `Yesterday, 04:30 PM`.
/// - Older `Added ...` labels, treated as the current moment.
///
/// [now] can be injected for deterministic tests.
/// Returns `null` when the value cannot be understood, so callers can
/// decide how to treat legacy records instead of crashing.
DateTime? tryParseTransactionDate(dynamic rawValue, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final raw = rawValue?.toString().trim() ?? '';

  if (raw.isEmpty) {
    return null;
  }

  final normalized = raw.toLowerCase();

  if (normalized == 'today' || normalized.startsWith('today,')) {
    return DateTime(reference.year, reference.month, reference.day);
  }

  if (normalized == 'yesterday' || normalized.startsWith('yesterday,')) {
    return DateTime(reference.year, reference.month, reference.day - 1);
  }

  if (normalized.startsWith('added')) {
    return reference;
  }

  return DateTime.tryParse(raw);
}

/// Tells whether [date] falls inside the named [filter] period.
///
/// Supported filters: `All time`, `Today`, `This week` (Monday to today),
/// `This month` and `Custom range` (inclusive [rangeStart]/[rangeEnd]).
/// A custom range without both bounds matches nothing, and a [date] of
/// `null` only ever matches `All time`, so malformed or legacy dates
/// never crash the app and never leak into period filters.
bool isInDateFilter(
  DateTime? date,
  String filter, {
  DateTime? rangeStart,
  DateTime? rangeEnd,
  DateTime? now,
}) {
  if (filter == 'All time') {
    return true;
  }

  if (date == null) {
    return false;
  }

  final reference = now ?? DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(reference.year, reference.month, reference.day);

  switch (filter) {
    case 'Today':
      return day == today;
    case 'This week':
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      return !day.isBefore(weekStart) && !day.isAfter(today);
    case 'This month':
      return date.year == reference.year && date.month == reference.month;
    case 'Custom range':
      if (rangeStart == null || rangeEnd == null) {
        return false;
      }
      final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
      final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
      return !day.isBefore(start) && !day.isAfter(end);
    default:
      return true;
  }
}

/// Formats [amount] with thousands separators and two decimals,
/// e.g. `12450.5` becomes `12,450.50`. The sign is never included.
String formatMoney(double amount) {
  final parts = amount.abs().toStringAsFixed(2).split('.');
  final digits = parts[0];
  final buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return '${buffer.toString()}.${parts[1]}';
}

/// Income total of [transactions] (sum of positive amounts).
double totalIncomeOf(List<Map<String, dynamic>> transactions) {
  return transactions.fold<double>(0, (total, transaction) {
    final amount = transactionAmount(transaction);
    return total + (amount > 0 ? amount : 0);
  });
}

/// Expense total of [transactions] (absolute sum of negative amounts).
double totalExpensesOf(List<Map<String, dynamic>> transactions) {
  return transactions.fold<double>(0, (total, transaction) {
    final amount = transactionAmount(transaction);
    return total + (amount < 0 ? amount.abs() : 0);
  });
}
