import 'transaction_utils.dart';

/// A single wallet transaction.
///
/// Replaces the loosely typed `Map<String, dynamic>` records that used to
/// travel between screens, so field names and types are checked by the
/// compiler instead of failing at runtime.
///
/// [amount] follows the app's convention: negative values are expenses,
/// positive values are income. [date] keeps the raw stored value (an
/// ISO-8601 string for new records, or a legacy label such as
/// "Today, 10:42 AM" for older demo data); use [parsedDate] for logic.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });

  /// Stable unique identifier, used to target edits and deletions.
  final String id;

  final String title;
  final String category;

  /// Negative for expenses, positive for income.
  final double amount;

  /// Raw stored date value; see [parsedDate].
  final String date;

  bool get isIncome => amount > 0;
  bool get isExpense => amount < 0;

  /// The calendar date of this transaction, or `null` when the stored
  /// value cannot be understood. Callers decide how to treat undatable
  /// legacy records (the statistics screen counts them as current month,
  /// period filters exclude them).
  DateTime? get parsedDate => tryParseTransactionDate(date);

  static int _idCounter = 0;

  /// Generates a locally unique id without any external dependency.
  static String generateId() {
    _idCounter += 1;
    return 'tx-${DateTime.now().microsecondsSinceEpoch}-$_idCounter';
  }

  WalletTransaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    String? date,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  /// Builds a transaction from stored JSON.
  ///
  /// Tolerates legacy records: a missing [id] gets a freshly generated
  /// one, and malformed amounts fall back to zero instead of throwing.
  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final double amount;
    if (rawAmount is num) {
      amount = rawAmount.toDouble();
    } else {
      amount = double.tryParse(rawAmount?.toString() ?? '') ?? 0;
    }

    final rawId = json['id']?.toString() ?? '';

    return WalletTransaction(
      id: rawId.isEmpty ? generateId() : rawId,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      amount: amount,
      date: json['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
    };
  }
}

/// Income total of [transactions] (sum of positive amounts).
double totalIncomeOf(List<WalletTransaction> transactions) {
  return transactions.fold<double>(0, (total, transaction) {
    return total + (transaction.isIncome ? transaction.amount : 0);
  });
}

/// Expense total of [transactions] (absolute sum of negative amounts).
double totalExpensesOf(List<WalletTransaction> transactions) {
  return transactions.fold<double>(0, (total, transaction) {
    return total + (transaction.isExpense ? transaction.amount.abs() : 0);
  });
}
