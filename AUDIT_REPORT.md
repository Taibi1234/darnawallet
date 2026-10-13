# Phase A — Audit & Baseline Report (2026-10-14)

Status: COMPLETE — all 36 tests pass, `flutter analyze` clean, `dart format` clean.

Changes preserved in commit `b8628b7` (existing). Uncommitted modifications are good recent refactors (typed `WalletTransaction`, `AppColors`, recurring processing, data export) — kept intact.

## Audit results (priority order)

1. **Architecture:** `main.dart` (1085 lines) holds all state + all UI + persistence logic. Must split before any serious database work.
2. **Data:** SharedPreferences only. Must migrate to SQLite (`sqflite`) with versioned schema before any security/auth claims.
3. **Money model:** `double` is risky for financial sums. Must switch to integer minor units (MAD cents) with consistent rounding rules.
4. **Validation:** Form-level only; needs repository/model-level guards.
5. **Errors:** Silent swallowing in recurring processor; needs structured exception types.
6. **Tests:** Only 3 files (happy-path heavy). Need repository, migration, edge-case, and empty-state coverage.
7. **UI:** No empty-state or loading-state patterns; budget categories fixed; no list sorting.
8. **Docs:** No CHANGELOG, CONTRIBUTING, SECURITY, PR/issue templates.
9. **CI:** Present but needs Flutter version pinning and stronger gates.
10. **Secrets:** None found. `HOME/`, `kimi-debug-session_*.zip`, `.bak` files need exclusion from tracking.

## Actual commands executed (with real results)
- `flutter analyze` → No issues found!
- `flutter test` → 36 tests passed!
- `dart format --set-exit-if-changed` → clean
- `flutter pub outdated` → 5 older dependencies; no critical vulnerabilities reported by built-in analysis
- `git diff --check` → whitespace OK
- `git status` → branch `main`, in sync with `origin`

## What still needs user decisions
- Auth model (Phase D): biometric/app-lock only (local, no account backend) is safe. Multi-device/cloud requires a backend design not present here — must be confirmed. If only local lock, proceed; if real accounts needed, scope must be defined first.
- SQLite database: proceed with `sqflite` and versioned migrations (recommended).
- Currency: single-currency (MAD) is correct for now; multi-currency out of scope unless requested.
