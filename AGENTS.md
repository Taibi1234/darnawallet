# DarnaWallet — Agent Instructions

DarnaWallet is a personal finance tracking Flutter application for managing income, expenses, monthly budgets, recurring transactions, and spending statistics. All data is stored locally on the device using `shared_preferences`. This is a learning/portfolio project with demo data — it never touches real money or bank accounts.

## Project Overview

**Technology Stack:**
- Flutter 3.47+ / Dart 3.13+
- Material 3 widgets with custom color scheme (navy: `#142B3B`, green: `#35C995`)
- `shared_preferences` ^2.5.6 for local persistence
- `file_picker` ^8.1.6 for cross-platform file selection
- `path_provider` ^2.1.5 for temporary file storage
- `share_plus` ^10.1.2 for sharing exports
- `cupertino_icons` ^1.0.8 for iOS-style icons
- `flutter_lints` ^6.0.0 for static analysis
- No backend, no network calls, no authentication

**Target Platforms:**
- Windows desktop (primary development platform)
- Web (Chrome/Edge)
- Android (requires Android SDK)
- iOS and macOS (project structure present but not actively tested)

**Architecture:**
- Single-page app with bottom navigation (5 tabs: Home, Activity, Statistics, Budgets, Profile)
- State managed locally in StatefulWidgets
- Data persistence through SharedPreferences JSON serialization
- Strongly-typed models: `WalletTransaction`, `RecurringTransaction`, `CategoryList`
- Shared theme via `app_theme.dart` with `AppColors` constants

**Current Version:** v1.1.0 (as of 2026-10-12)

## Build and Test Commands

**Setup:**
```powershell
flutter pub get
```

**Run the app:**
```powershell
flutter run            # pick a device: windows, chrome, or an emulator
```

**Code quality checks (run before committing):**
```powershell
dart format --output=none --set-exit-if-changed .   # formatting check
flutter analyze                                      # static analysis
flutter test                                         # unit + widget tests
```

**Build release artifacts:**
```powershell
flutter build windows --release   # Windows desktop (.exe)
flutter build web --release       # static web build in build/web
flutter build apk --release       # Android (requires Android SDK)
```

## Project Structure

```
lib/
  main.dart                        App entry, dashboard, add/edit/delete logic
  transaction_management_page.dart Searchable/filterable activity list
  statistics_dashboard.dart        Charts and financial summaries
  budget_management_page.dart      Monthly category budgets and alerts
  profile_page.dart                Profile, stats, data management, automation
  recurring_transactions_page.dart Recurring transaction management UI
  category_management_page.dart    Custom category management UI
  app_theme.dart                   Shared color constants and Material 3 theme
  transaction.dart                 WalletTransaction model
  recurring_transaction.dart       RecurringTransaction model
  category_manager.dart            Custom category storage utilities
  data_export.dart                 CSV/JSON export and import utilities
  recurring_processor.dart         Automatic recurring transaction generation
  transaction_utils.dart           Shared parsing/formatting/filter helpers

test/
  widget_test.dart                 Widget and flow tests
  transaction_utils_test.dart      Unit tests for shared helpers
  transaction_test.dart            Unit tests for WalletTransaction model

.github/workflows/
  flutter.yml                      CI: format check, analyze, test
```

### Key Files

**`lib/main.dart`**
- App entry point (`DarnaWalletApp`, `WalletHomePage`)
- Dashboard UI with balance card, income/expense summary, recent transactions
- Add/edit/delete transaction dialogs with validation
- Persistence logic (`_saveTransactions`, `_loadTransactions`)
- Processes recurring transactions on startup via `processRecurringTransactions()`
- Seeds 4 demo transactions on first launch
- Constants: `openingBalance = 6426.50`, `storageKey = 'darnawallet_transactions'`, `appVersion = '1.1.0'`

**`lib/app_theme.dart`**
- Centralized color constants in `AppColors` class (navy, green, background, white, red, orange, chartColors)
- `buildAppTheme()` — Material 3 theme configuration with color scheme, app bar, FAB, and card themes
- Private constructor prevents direct instantiation

**`lib/transaction.dart`**
- `WalletTransaction` class — strongly-typed transaction model
- Fields: `id`, `title`, `category`, `amount` (negative = expense, positive = income), `date` (raw string)
- `parsedDate` getter returns `DateTime?` (tolerates legacy demo labels like "Today, 10:42 AM")
- `fromJson`/`toJson` for persistence, tolerates missing fields for legacy data
- `isIncome`/`isExpense` getters for type checking
- `totalIncomeOf()`, `totalExpensesOf()` — aggregate calculations (module-level functions)
- `copyWith()`, `generateId()` helpers

**`lib/recurring_transaction.dart`**
- `RecurringTransaction` model for automatic income/expenses
- `RecurringFrequency` enum: daily, weekly, biweekly, monthly, yearly
- `shouldProcessToday()` logic determines when to generate transactions
- Fields: id, title, category, amount, frequency, startDate, endDate, lastProcessedDate, isActive

**`lib/recurring_processor.dart`**
- `processRecurringTransactions()` — scans all active recurring transactions and generates new transactions if due
- Called automatically on app startup in `_loadTransactions()`
- Updates `lastProcessedDate` after generation
- Returns count of generated transactions
- Silently fails rather than breaking the app

**`lib/category_manager.dart`**
- Custom category storage: `CategoryList` with income and expense categories
- `CategoryType` enum: income, expense
- `loadCategories()`, `saveCategories()`, `resetCategoriesToDefaults()`
- Storage key: `categoriesStorageKey = 'darnawallet_custom_categories'`
- Defaults: `defaultIncomeCategories`, `defaultExpenseCategories`
- `CategoryList.defaults()` factory for fallback

**`lib/data_export.dart`**
- `exportTransactionsToCSV()` — generates CSV with proper escaping
- `exportTransactionsToJSON()` — pretty-printed JSON backup
- `importTransactionsFromJSON()` — restore from backup
- `saveAndShareCSV()`, `saveAndShareJSON()` — cross-platform save/share (Windows, web, mobile)
- `pickAndReadJSONBackup()` — file picker for restore

**`lib/profile_page.dart`**
- Profile tab with account summary (balance, transaction count, totals)
- Automation section: links to recurring transactions and category management
- Data management: CSV export, JSON backup/restore, clear all data
- About section with app info

**`lib/recurring_transactions_page.dart`**
- Full CRUD for recurring transactions
- Add/edit dialog with frequency selector, date pickers, category dropdown
- Active/inactive toggle per transaction
- Empty state with helpful message
- Storage key: `recurringStorageKey = 'darnawallet_recurring_transactions'`

**`lib/category_management_page.dart`**
- Manage custom income and expense categories
- Add, edit, delete categories
- Reset to defaults option
- Warns about existing transactions when deleting

**`lib/transaction_utils.dart`**
- `tryParseTransactionDate()` — parses ISO-8601 or legacy demo labels ("Today", "Yesterday", "Added...")
- `isInDateFilter()` — date period filtering (All time, Today, This week, This month, Custom range)
- `formatMoney()` — thousands separators, two decimals, no sign (e.g., `12,450.50`)

**`lib/transaction_management_page.dart`**
- Searchable/filterable transaction list
- Filters: text search (title/category), type (All/Income/Expenses), category dropdown, date period
- Live filtered summary: income, expenses, net cash flow
- Edit/delete actions via popup menu with confirmation dialog

**`lib/statistics_dashboard.dart`**
- Income vs. expenses comparison bars
- Spending by category with percentages and progress bars
- Six-month income/expense trend chart
- Transaction summary (counts, average expense)
- **Important:** Undatable legacy records count toward the current month so they stay visible in charts

**`lib/budget_management_page.dart`**
- Monthly per-category spending limits
- Progress bars with color coding: green (under 80%), orange (80-100%), red (over budget)
- Alerts when a category reaches 80% or exceeds its budget
- Persistence: `budgetStorageKey = 'darnawallet_monthly_budgets'`
- Fixed category list: `budgetCategories` (10 categories including "Other")

## Code Style Guidelines

### Dart/Flutter Conventions
- Follow `flutter_lints` rules (enforced via `analysis_options.yaml`)
- Use `dart format` before every commit (CI fails on formatting violations)
- Prefer `const` constructors where possible
- Use named parameters for widget constructors
- Explicit types for public APIs, inference allowed within function bodies
- Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`

### Naming Patterns
- Constants: `camelCase` (e.g., `openingBalance`, `storageKey`)
- Color constants: use `AppColors.navy`, `AppColors.green`, etc. from `app_theme.dart`
- Private methods: `_leadingUnderscore` (e.g., `_saveTransactions`, `_loadTransactions`)
- Widget builders: `_buildWidgetName` (e.g., `_buildDashboard`, `_buildTransaction`)
- Class names: `PascalCase` (e.g., `WalletTransaction`, `RecurringTransaction`)
- File names: `snake_case` (e.g., `transaction_management_page.dart`)

### State Management
- Local state in `StatefulWidget` via `setState()`
- Pass callbacks down for child widgets to trigger parent state changes (e.g., `onEdit`, `onDelete`, `onDataChanged`)
- Always check `mounted` before calling `setState()` after async operations

### Widget Structure
- Many small files over few large ones
- Extract reusable widgets as private classes with underscore prefix (e.g., `_SummaryCard`, `_ComparisonBar`)
- Use `StatelessWidget` for pure presentation, `StatefulWidget` only when state is needed

### Error Handling
- Wrap SharedPreferences operations in `try-catch`
- Fall back to demo data or empty state on load failure
- Show user-friendly snackbar messages for errors
- Never crash — tolerate malformed legacy data (see `WalletTransaction.fromJson`)

### Layout and Responsiveness
- Dashboard and pages use `ListView` with `ConstrainedBox(maxWidth: 760)` for wide screens
- `FittedBox` with `scaleDown` for amounts that might overflow (e.g., large balances)
- Tests use a large surface (`1200x2600`) to avoid scroll-dependent failures

## Data Model and Persistence

### Transaction Storage Format
Stored in SharedPreferences as JSON array under key `'darnawallet_transactions'`:
```dart
[
  {
    "id": "tx-1728675137000000-1",         // generated, unique
    "title": "Monthly salary",
    "category": "Salary",
    "amount": 6500.0,                      // positive = income, negative = expense
    "date": "2026-10-11T20:52:17.000"      // ISO-8601 for new records
  },
  {
    "title": "Grocery shopping",           // legacy demo record (no id)
    "category": "Food & groceries",
    "amount": -245.50,
    "date": "Today, 10:42 AM"              // legacy demo label
  }
]
```

**Legacy Compatibility:**
- Missing `id` → generate fresh ID on load (`WalletTransaction.fromJson`)
- Malformed `amount` → fall back to `0`
- Legacy `date` labels ("Today, 10:42 AM") → parsed by `tryParseTransactionDate()`
- Unparseable dates → `parsedDate` returns `null`, excluded from period filters but counted in statistics

### Budget Storage Format
Stored in SharedPreferences as JSON array under key `'darnawallet_monthly_budgets'`:
```dart
[
  {
    "category": "Food & groceries",
    "limit": 1500.0                        // monthly spending limit in MAD
  }
]
```

### Recurring Transaction Storage Format
Stored in SharedPreferences as JSON array under key `'darnawallet_recurring_transactions'`:
```dart
[
  {
    "id": "rec-1728675137000000",
    "title": "Monthly rent",
    "category": "Housing",
    "amount": -3000.0,
    "frequency": "monthly",                // daily, weekly, biweekly, monthly, yearly
    "startDate": "2026-01-01T00:00:00.000",
    "endDate": null,                       // null = no end date
    "lastProcessedDate": "2026-10-01T00:00:00.000",
    "isActive": true
  }
]
```

### Custom Categories Storage Format
Stored in SharedPreferences as JSON object under key `'darnawallet_custom_categories'`:
```dart
{
  "income": ["Salary", "Business", "Gift", "Other income", "Custom income category"],
  "expense": ["Food & groceries", "Food & drinks", "Transport", "Shopping", "Utilities", "Other expense"]
}
```

**Categories handling:**
- Defaults are loaded from `category_manager.dart` constants
- Custom categories can be added, edited, or removed
- Reset to defaults removes the storage key, falling back to constants
- Transaction dialogs currently use hardcoded category lists (infrastructure exists but not fully integrated yet)

### Categories
**Default income categories:**
- Salary, Business, Gift, Other income

**Default expense categories:**
- Food & groceries, Food & drinks, Transport, Shopping, Utilities, Other expense

**Budget categories:** (fixed list in `budget_management_page.dart`)
- Food & groceries, Food & drinks, Transport, Shopping, Utilities, Entertainment, Health, Education, Housing, Other

**Custom categories:**
- Users can add/edit/remove categories via Profile > Manage Categories
- Stored in `categoriesStorageKey = 'darnawallet_custom_categories'`
- Reset to defaults removes custom categories

## Testing Instructions

### Test Organization
- Widget/integration tests: `test/widget_test.dart`
- Unit tests: `test/transaction_utils_test.dart`, `test/transaction_test.dart`

### Test Coverage Areas
1. **Persistence:** saved transactions load correctly, demo data seeds on first launch, recurring transactions processed
2. **Add transaction flow:** form validation, snackbar confirmation, balance update
3. **Search and filters:** text search, type filter, category filter, date periods (Today, This week, Custom range)
4. **Transaction utilities:** date parsing (ISO-8601 and legacy labels), period filtering, money formatting, totals
5. **WalletTransaction model:** JSON serialization, helpers, copyWith, totals

### Running Tests
```powershell
flutter test                                 # all tests
flutter test test/widget_test.dart           # widget tests only
flutter test test/transaction_utils_test.dart # unit tests for utilities
flutter test test/transaction_test.dart      # unit tests for model
```

### Test Patterns
- Use `testWidgetsLarge()` helper for widget tests (sets large viewport `1200x2600`)
- Mock `SharedPreferences` in setUp: `SharedPreferences.setMockInitialValues({})`
- Always `await tester.pumpAndSettle()` after async state changes
- Inject `now` parameter for deterministic date-related tests

### Adding New Tests
When adding features:
1. Add unit tests for new utility functions
2. Add model tests for new data classes
3. Add widget tests for new UI flows
4. Test both the happy path and edge cases (empty state, malformed data, validation errors)
5. Verify snackbar messages appear correctly

## Security Considerations

**This app has minimal security requirements because:**
- No user authentication or accounts
- No network requests or backend communication
- No real money, bank connections, or PII
- All data stays local on the device

**What to protect:**
- Data integrity: validate user input (amounts > 0, non-empty titles)
- Type safety: use strongly-typed models (`WalletTransaction`, `RecurringTransaction`)
- Graceful degradation: never crash on malformed stored data

**Not required:**
- Encryption (demo data only)
- Input sanitization for XSS (no web views or HTML rendering)
- Rate limiting (no network calls)

## Common Development Tasks

### Adding a New Feature
1. Plan the feature (identify affected files, data model changes)
2. Update data models if needed (add new fields, maintain backward compatibility)
3. Write tests first (TDD)
4. Implement the feature
5. Update UI to integrate the feature
6. Run full verification: format, analyze, test, build
7. Update README and AGENTS.md

### Working with Custom Categories
- Categories are managed via `category_manager.dart`
- Load with `loadCategories()`, save with `saveCategories()`
- Transaction dialogs currently use hardcoded categories (future improvement: load dynamically)
- Budget categories are still a fixed list

### Working with Recurring Transactions
- Model: `RecurringTransaction` in `recurring_transaction.dart`
- Processing: `processRecurringTransactions()` in `recurring_processor.dart`
- UI: `RecurringTransactionsPage` for CRUD operations
- Auto-processing happens on app startup in `_loadTransactions()`

### Adding Data Export/Import Features
- Use `data_export.dart` utilities
- CSV: `exportTransactionsToCSV()`, `saveAndShareCSV()`
- JSON: `exportTransactionsToJSON()`, `importTransactionsFromJSON()`
- Cross-platform file operations handled by `file_picker` and `share_plus`

### Modifying Persistence Format
1. Update JSON serialization in model's `toJson()`/`fromJson()`
2. Maintain backward compatibility — tolerate missing fields with defaults
3. Test migration from old format with mock stored values
4. Update this `AGENTS.md` to document the new format

### Changing the Color Scheme
- All colors now centralized in `app_theme.dart`
- Use `AppColors.navy`, `AppColors.green`, `AppColors.background`, etc.
- Update `buildAppTheme()` for theme-wide changes
- Chart colors: `AppColors.chartColors` list

## Known Limitations and Future Improvements

**Current features (v1.1.0):**
- ✅ Core transaction tracking (income/expenses)
- ✅ Search and filters (text, type, category, date periods)
- ✅ Statistics dashboard with charts and summaries
- ✅ Monthly budgets with progress tracking and alerts
- ✅ Recurring transactions (daily, weekly, biweekly, monthly, yearly)
- ✅ Custom categories management
- ✅ CSV export and JSON backup/restore
- ✅ Profile page with data management

**Current limitations:**
- Data lives only on device (backup/restore available, but no automatic cloud sync)
- Transaction dialogs still use hardcoded category lists (infrastructure exists but not fully integrated)
- Notifications tab is a placeholder by design
- Single currency (MAD only); no multi-currency support
- No transaction attachments (receipts, notes)

**Planned improvements:**
- Optional cloud sync
- Multi-currency support
- Transaction attachments
- Integrate custom categories into transaction dialogs dynamically
- Enhanced statistics (custom date ranges, export charts)

## CI/CD

**GitHub Actions workflow (`.github/workflows/flutter.yml`):**
- Triggers on push/PR to `main` branch
- Runs on `ubuntu-latest`
- Steps:
  1. Checkout repository
  2. Set up Flutter (stable channel, with cache)
  3. Install dependencies (`flutter pub get`)
  4. Verify formatting (`dart format --output=none --set-exit-if-changed .`)
  5. Analyze source (`flutter analyze`)
  6. Run tests (`flutter test`)

**All steps must pass for CI to succeed.**

## Agent Workflow Recommendations

When working on this project:

1. **Before making changes:**
   - Read relevant files (don't assume structure from memory)
   - Check existing patterns (widget builders, state management, persistence)
   - Look for similar existing code to maintain consistency
   - Review `app_theme.dart` for color constants

2. **When adding features:**
   - Write tests first (TDD) — add unit tests for utilities, widget tests for UI flows
   - Update all affected pages (don't break consistency across tabs)
   - Maintain backward compatibility with stored data formats
   - Use strongly-typed models instead of maps
   - Update `AGENTS.md` if the change affects project structure or conventions
   - Update README with user-facing feature descriptions

3. **Before committing:**
   - Run `dart format .` to auto-format
   - Run `flutter analyze` and fix all issues
   - Run `flutter test` and ensure all tests pass
   - Verify the app runs: `flutter run` on Windows or web
   - Build release if making significant changes: `flutter build windows --release`

4. **Code review checklist:**
   - Input validation on all form fields
   - `mounted` checks before `setState()` after async operations
   - Graceful error handling with user-friendly messages
   - Consistent naming (private methods start with `_`)
   - No hardcoded strings that should be constants
   - Tests cover new functionality
   - Use `AppColors.*` from `app_theme.dart` instead of inline color definitions

## Troubleshooting Common Issues

**Problem: Formatting check fails in CI**
- Solution: Run `dart format .` locally before committing

**Problem: Tests fail with layout overflow**
- Solution: Ensure tests use `testWidgetsLarge()` helper or increase viewport size

**Problem: SharedPreferences not working in tests**
- Solution: Call `SharedPreferences.setMockInitialValues({})` in `setUp()`

**Problem: State updates after widget disposed**
- Solution: Add `if (!mounted) return;` before `setState()` calls after async operations

**Problem: Legacy demo data breaks new feature**
- Solution: Check model's `fromJson()` — add fallback for new field, test with legacy JSON

**Problem: Recurring transactions not generating**
- Solution: Check `shouldProcessToday()` logic, verify `lastProcessedDate` is updated, ensure transactions are marked `isActive`

**Problem: Custom categories not appearing**
- Solution: Verify `saveCategories()` is called, check SharedPreferences key, ensure dialogs call `loadCategories()`

---

**Last updated:** 2026-10-12 (v1.1.0)

This project follows Flutter best practices and Material Design guidelines. When in doubt, refer to the existing code patterns and maintain consistency with the established architecture.
