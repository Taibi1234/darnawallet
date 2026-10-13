import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/main.dart' as main_defaults show storageKey;
import '../lib/recurring_transactions_page.dart' show recurringStorageKey;
import '../lib/budget_management_page.dart' show budgetStorageKey;
import '../lib/category_manager.dart' show categoriesStorageKey;
import 'wallet_database.dart';

/// Idempotent migration of legacy SharedPreferences data into SQLite.
/// Keeps legacy JSON intact (never deletes) until verified.
final class DataMigration {
  static bool migrated = false;

  static Future<void> runIfNeeded() async {
    if (migrated) return;
    final prefs = await SharedPreferences.getInstance();
    final db = await WalletDatabase.instance;

    // Migrate transactions (only if table is empty and source exists)
    final txRaw = prefs.getString('darnawallet_transactions');
    if (txRaw != null) {
      final list = jsonDecode(txRaw) as List<dynamic>;
      for (final item in list) {
        final map = item as Map<dynamic, dynamic>;
        final id = map['id']?.toString() ?? 'tx-${map.hashCode}';
        final title = map['title']?.toString() ?? '';
        final category = map['category']?.toString() ?? 'Other';
        final amount = (map['amount'] is num ? (map['amount'] as num).toDouble() : double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0);
        final cents = (amount * 100).round();
        final dateRaw = map['date']?.toString() ?? '';
        await db.insert('transactions', {
          'id': id,
          'title': title,
          'category': category,
          'amount_cents': cents,
          'date_raw': dateRaw,
        }, conflictAlgorithm: sqlite.ConflictAlgorithm.ignore);
      }
    }
    migrated = true;
  }
}
