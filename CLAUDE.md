# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository. See also `AGENTS.md`, which has the same project reference content.

## What is this project?

DarnaWallet is a **personal finance tracker built with Flutter**. It's a single-page demo/portfolio app: no backend, no network calls, no accounts. All data lives on-device in `shared_preferences` as JSON. Amounts are in MAD only; the app ships with demo transactions and never touches real money.

**Version:** v1.1.0 (2026-10-11). **Target dev platform:** Windows desktop; web (Chrome/Edge) also supported.

**Stack:** Flutter 3.47+ / Dart 3.13.5+, Material 3, `shared_preferences`, `file_picker`, `path_provider`, `share_plus`, `flutter_lints`.

## How to build, lint, and test

```powershell
flutter pub get                        # install deps (always first)

flutter run            # pick a device: windows, chrome, or an emulator
```

**Code quality (run before committing; CI enforces all of these):**
```powershell
dart format --output=none --set-exit-if-changed .   # formatting gate
flutter analyze                                      # static analysis
flutter test                                         # unit + widget tests
```

**Run a single test file:**
```powershell
flutter test test/widget_test.dart
flutter test test/transaction_utils_test.dart
flutter test test/transaction_test.dart
```

**Release builds:**
```powershell
flutter build windows --release   # .exe
flutter build web --release       # build/web
flutter build apk --release       # Android (needs Android SDK)
```

**CI** (`.github/workflows/flutter.yml`): on push/PR to `main` — setup Flutter stable with cache, `flutter pub get`, format check, analyze, then tests. Every step must pass.

## Big-picture architecture

### The app is a single StatefulWidget holding all state

Everything hinges on `lib/main.dart`:

- `DarnaWalletApp` — just a `MaterialApp` with `theme: buildAppTheme()`.
- `WalletHomePage` (state class `_WalletHomePageState`) — the entire app. It owns the single source of truth: `List<WalletTransaction> transactions`, plus the bottom-nav `selectedIndex` and `isLoading`.
- The 5 bottom tabs: **Home** (0), **Activity** (1), **Statistics** (2), **Budgets** (3), **Profile** (4). Tabs 2–4 are plain delegate pages (`TransactionManagementPage`, `StatisticsDashboard`, `BudgetManagementPage`, `ProfilePage`) passed the transaction list and callbacks. Only tabs 0–1 are built directly inside `_WalletHomePageState`.

### Lifecycle / data flow (read this before touching main.dart)

1. `initState()` → `_loadTransactions()`:
   - **First:** `processRecurringTransactions()` runs (from `recurring_processor.dart`) and **mutates storage** — it generates today's due recurring transactions and re-saves both the transaction and recurring-list JSON.
   - Then reads `'darnawallet_transactions'` from SharedPreferences; if missing, seeds 4 demo records and saves them.
   - Each record goes through `WalletTransaction.fromJson` (tolerates legacy formats — no `id`, string amounts, label-like dates).
   - `setState()` publishes the list, then the UI rebuilds.
2. Reads and mutations go through `_saveTransactions()`, which JSON-encodes the whole list. All failures are caught, fall back to demo data, and show a SnackBar — the app never crashes on bad storage.
3. **Adding** a transaction: modal dialog (segmented button for income/expense, title, amount, category) → `setState(() => transactions.insert(0, tx))` (newest first) → save → undo-capable SnackBar.
4. **Editing**: dialog pre-filled with the selected transaction → replace in list by `id` → save on failure, roll back.
5. **Deleting**: remove from list first → save → SnackBar with **Undo** that re-inserts at the original index and re-saves.
6. Navigation taps just change `selectedIndex`; all pages read state via passed-in callbacks (`onEdit`, `onDelete`) or event callbacks (`onDataChanged`).

### Key constants in main.dart
- `openingBalance = 6426.50` — dashboard balance is `openingBalance + totalIncome - totalExpenses`.
- `storageKey = 'darnawallet_transactions'`.
- `appVersion = '1.1.0'`.

### Money model
- `amount` is a `double`; **positive = income, negative = expense**. Categories are chosen from hardcoded lists per type in the add/edit dialogs (custom-category infrastructure exists in `category_manager.dart` but is not wired into transaction entry yet).

### Recurring transactions — how they become normal transactions
`recurring_processor.dart::processRecurringTransactions()` is the only background worker: on startup it reads active recurring entries, checks `shouldProcessToday()` (based on `frequency` and `lastProcessedDate`), appends generated `WalletTransaction`s to storage, updates `lastProcessedDate`, and re-saves. If anything fails it silently continues. The generated rows are indistinguishable from manual entries once saved.

### Persistence keys (SharedPreferences)
- `'darnawallet_transactions'` — list of transaction JSON objects (`transaction.dart`).
- `'darnawallet_recurring_transactions'` — list of recurring entries (`recurring_transaction.dart`).
- `'darnawallet_monthly_budgets'` — per-category limit list (`budget_management_page.dart`).
- `'darnawallet_custom_categories'` — `{income: [...], expense: [...]}` (`category_manager.dart`).

### Where each concern lives
- `transaction.dart` — `WalletTransaction` model, `fromJson`/`toJson`, `parsedDate`, `isIncome`/`isExpense`, module-level `totalIncomeOf`/`totalExpensesOf`, `copyWith`/`generateId`.
- `transaction_utils.dart` — `tryParseTransactionDate()` (ISO-8601 + legacy labels like "Today, 10:42 AM"), `isInDateFilter()` (All time / Today / This week / This month / custom range), `formatMoney()` (thousands separators, e.g. `12,450.50`).
- `app_theme.dart` — `AppColors` color constants + `buildAppTheme()` (Material 3 scheme, app bar, FAB, card themes). Use `AppColors.x` everywhere; never inline colors.
- `transaction_management_page.dart` — Activity tab: text search (title/category), type/category/date filters, live summary (income / expenses / net).
- `statistics_dashboard.dart` — income-vs-expenses comparison, spending-by-category with progress bars, six-month trend chart, summary rows. Legacy un-parseable records are folded into the current month so they appear in charts.
- `budget_management_page.dart` — per-category monthly limits, color-coded progress (green <80%, orange 80–100%, red >100%), alerts at 80% and over. Fixed 10-category list.
- `recurring_transaction.dart` — `RecurringTransaction` + `RecurringFrequency` enum (daily/weekly/biweekly/monthly/yearly).
- `category_manager.dart` — `CategoryList`, `CategoryType`, `loadCategories`/`saveCategories`/`resetCategoriesToDefaults`.
- `data_export.dart` — CSV export, pretty JSON backup, JSON restore, cross-platform save/share via `file_picker` + `share_plus`.
- `recurring_transactions_page.dart` — recurring CRUD UI.
- `category_management_page.dart` — custom category CRUD + reset.
- `profile_page.dart` — account summary, automation links, data management (export/restore/clear), about.

## Data model / storage formats (backward compatibility)

Transactions stored as a JSON array:
```json
[
  { "id": "tx-1728675137000000-1", "title": "Monthly salary", "category": "Salary", "amount": 6500.0, "date": "2026-10-11T20:52:17.000" },
  { "title": "Grocery shopping", "category": "Food & groceries", "amount": -245.50, "date": "Today, 10:42 AM" }   // legacy, no id
]
```
`fromJson` tolerates: missing `id` (fresh id generated), malformed `amount` → 0, unparseable dates → `parsedDate` is `null` (excluded from period filters, still counted in statistics). Dates for new records are ISO-8601 timestamps.

## Code conventions (mirrors `AGENTS.md` / `analysis_options.yaml`)

- `flutter_lints` rules apply; CI fails on formatting, so run `dart format .` before every commit.
- Private members `_leadingUnderscore`; widget builders `_buildName`; class names `PascalCase`; file names `snake_case`; constants `camelCase` (not UPPER_SNAKE).
- Colors only via `AppColors.*` (e.g. `AppColors.navy`, `AppColors.green`, `AppColors.chartColors`).
- State: `StatefulWidget` + `setState`; pass callbacks (`onEdit`, `onDelete`, `onDataChanged`) for child pages. **Always `if (!mounted) return;` before `setState()` after async work.**
- Reusable UI goes into private widget classes (`_SummaryCard`, `_ComparisonBar`); small Stateless widgets for pure presentation.
- Wide layout: `ListView` inside a `ConstrainedBox(maxWidth: 760)`; amounts that may overflow go through `FittedBox(fit: BoxFit.scaleDown)`.
- Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
- Errors: wrap SharedPreferences in try-catch, fall back to demo/empty state, show user-friendly SnackBar messages. Never crash on malformed legacy data.

## Testing

- `test/widget_test.dart` — widget/flow tests (dashboard load, saved-data load, add/edit/delete flows, filters).
- `test/transaction_utils_test.dart` — unit tests for date parsing, filtering, money formatting.
- `test/transaction_test.dart` — `WalletTransaction` model serialization and helpers.

**Patterns:**
- Tests use `testWidgetsLarge()` (viewport `1200x2600`, `devicePixelRatio = 1.0`) to avoid scroll/layout failures — don't write tests against a tiny viewport.
- `setUp()` mocks SharedPreferences with `SharedPreferences.setMockInitialValues({})`.
- Always `await tester.pumpAndSettle()` after async state changes.
- SnackBar messages are assertions targets (e.g. "Transaction saved successfully.", undo messages).

## Working here: recommended order

1. Read the relevant source files (models + the page that owns the state).
2. Check existing patterns in those files before writing new code.
3. Write tests (utility unit tests, model tests, then widget flow tests).
4. Implement the feature, using `AppColors` and the app's private widget/class conventions.
5. Run `dart format .` → `flutter analyze` → `flutter test`.
6. If you changed the app's behavior, structure, or data format, update `AGENTS.md` and `README.md` to match.

## Known limitations worth knowing

- Custom categories are managed but not yet wired into the add/edit transaction dialogs; budget categories are a fixed list.
- Notifications tab is a placeholder by design.
- MAD only; no cloud sync (backup/restore via JSON is available).
- Legacy demo dates like "Today, 10:42 AM" must be tolerated everywhere dates are parsed.
