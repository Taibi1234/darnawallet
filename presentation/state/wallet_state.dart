import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

final class WalletState {
  List<WalletTransaction> transactions = [];
  bool isLoading = true;

  double get totalIncome => transactions.fold<double>(0,
      (t, tx) => t + (tx.isIncome ? (tx.amount > 0 ? tx.amount : 0) : 0));
  double get totalExpenses => transactions.fold<double>(0,
      (t, tx) => t + (tx.isExpense ? tx.amount.abs() : 0));
}
