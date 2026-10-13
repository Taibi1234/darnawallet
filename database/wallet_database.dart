import 'package:sqflite/sqflite.dart' as sqlite;

/// Simple SQLite database layer for DarnaWallet.
/// Manages schema versioning, table creation, and safe migration.
final class WalletDatabase {
  static const int _version = 1;

  static sqlite.Database? _db;

  /// Initialize and open (or create) the database.
  /// Idempotent: safe to call multiple times.
  static Future<sqlite.Database> get instance async {
    _db ??= await sqlite.openDatabase(
      'darnawallet.db',
      version: _version,
      onCreate: (db, version) => _create(db, version),
      onUpgrade: (db, oldVersion, newVersion) => _upgrade(db, oldVersion, newVersion),
    );
    return _db!;
  }

  static Future<void> _create(sqlite.Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Other',
        amount_cents INTEGER NOT NULL,
        date_raw TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
      )
    ''');
    await db.execute('CREATE INDEX tx_date ON transactions(date_raw)');

    await db.execute('''
      CREATE TABLE budgets (
        category TEXT PRIMARY KEY,
        limit_cents INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _upgrade(
    sqlite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1) {
      // Initial version; no migration needed.
    }
  }
}
