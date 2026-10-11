# DarnaWallet

A personal wallet app built with Flutter. Track income and expenses, search
and filter your activity, review spending statistics, and manage monthly
budgets — all data is stored locally on the device.

> DarnaWallet ships with demo data and never touches real money or a bank
> account. It is a learning/portfolio project, not a financial service.

## Features

- **Dashboard** — total balance, income/expense overview, quick actions, and
  the most recent transactions.
- **Transactions** — add, edit, and delete income or expense records with
  validated forms (title, amount, category, automatic timestamp). Deletions
  can be undone from the snackbar.
- **Search and filters** — search by title or category; filter by type
  (income/expenses), category, and date period: Today, This week, This month,
  All time, or a custom date range. A live summary shows income, expenses,
  and net cash flow for the current filter.
- **Statistics** — income vs. expenses comparison, spending by category with
  percentages, six-month income/expense trends, and activity summaries. All
  figures are computed from the real transaction list.
- **Monthly budgets** — per-category spending limits with progress bars and
  alerts when a category reaches 80% of its budget or exceeds it.
- **Local persistence** — transactions and budgets survive app restarts via
  `shared_preferences`. Legacy demo records (e.g. dates stored as
  "Today, 10:42 AM") are still understood.

## Technology stack

- [Flutter](https://flutter.dev) 3.47+ / Dart 3.13+
- Material 3 widgets
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) for
  on-device storage
- `flutter_lints` for static analysis
- No backend, no accounts, no network calls

## Prerequisites

- Flutter SDK 3.47 or newer (`flutter --version`)
- For Windows desktop builds: Visual Studio with the "Desktop development
  with C++" workload
- For web builds: Chrome or Edge
- For Android builds: Android Studio / Android SDK (not required for the
  Windows and web builds above)

## Getting started

```powershell
git clone https://github.com/Taibi1234/darnawallet.git
cd darnawallet
flutter pub get
flutter run            # pick a device: windows, chrome, or an emulator
```

On the first launch the app seeds four demo transactions so the screens are
not empty. Add your own records or delete the demo ones — your changes are
saved locally.

## Running the tests

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .   # formatting check
flutter analyze                                      # static analysis
flutter test                                         # unit + widget tests
```

The suite covers transaction amount/date parsing, money formatting, date
period filtering, totals calculations, persistence across restarts, the
add-transaction flow, and the search/type/date filters.

## Building a release

```powershell
flutter build windows --release   # Windows desktop (.exe)
flutter build web --release       # static web build in build/web
flutter build apk --release       # Android (requires the Android SDK)
```

## Project structure

```
lib/
  main.dart                        app entry, dashboard, add/edit/delete logic
  transaction_management_page.dart searchable/filterable activity list
  statistics_dashboard.dart        charts and financial summaries
  budget_management_page.dart      monthly category budgets and alerts
  transaction_utils.dart           shared parsing/formatting/filter helpers
test/
  widget_test.dart                 widget and flow tests
  transaction_utils_test.dart      unit tests for the shared helpers
.github/workflows/
  flutter.yml                      CI: format check, analyze, test
```

## Current limitations and future improvements

- Data lives only on the device (no sync, backup, or export yet).
- The Profile and Notifications tabs are placeholders by design.
- Categories are fixed lists; custom categories are not supported yet.
- Amounts are displayed in MAD only; no multi-currency support.
- Planned: data export (CSV), custom categories, recurring transactions,
  and optional cloud sync.
