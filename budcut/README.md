# BudCut

A bold, personal budget & expense tracker built with Flutter. BudCut helps you
plan a monthly budget, track spending against it across multiple time ranges,
and keep recurring bills from quietly eating into your money — all in PKR.

## What it does

- **Login / Sign up** — Firebase email + password authentication gates the app.
- **Dashboard** — this month at a glance: spend vs budget, remaining, safe
  burn-per-day rate, average daily spend, a daily-spend bar chart, a
  category donut chart, per-category budget progress, and recent transactions.
- **Weekly / Monthly / Quarterly** — spending analysis across the current
  week, month, and rolling quarter, with per-day bars and category breakdowns.
- **Custom range** — pick any start/end dates and inspect spend for that window.
- **True Expense** — subtracts active recurring-bill liabilities from your
  budget to show your _real_ flexible money and what share is already committed.
- **Recurring Bills** — track weekly/monthly/yearly bills (normalized to a
  monthly liability), toggle them active/inactive, and let BudCut auto-log
  due bills as transactions.
- **Categories** — create, edit, and delete categories (defaults included),
  assign colors, mark them as fixed expenses, and set optional monthly caps
  with progress bars.
- **Quick Add** — a fast transaction entry modal from any tab.
- **Transactions** — full list with edit and delete, plus **export to CSV**
  via the share sheet.
- **Money formatting** — everything is stored and displayed in PKR with
  lakh/crore grouping (e.g. `2,50,000`).
- **Reset All Data** — wipe everything and start from a clean slate.

## Design language

Neo-Brutalist ("Modern Poster") UI: warm off-white canvas, crisp solid black
2px borders, hard-edge offset drop shadows, extrabold uppercase headings,
pastel accent palette, and `JetBrainsMono` for tabular currency figures.

## What it uses

| Concern           | Tech                                                              |
| ----------------- | ----------------------------------------------------------------- |
| Framework         | Flutter (Dart, Material 3)                                        |
| State management  | `provider` + `ChangeNotifier` (`AppState`)                        |
| Auth              | `firebase_core`, `firebase_auth` (email/password, web + Android)  |
| Local persistence | `shared_preferences` (JSON-encoded categories/transactions/bills) |
| Charts            | `fl_chart`                                                        |
| CSV export        | `csv`, `path_provider`, `share_plus`                              |
| Utilities         | `intl`, `uuid`                                                    |
| Launcher icons    | `flutter_launcher_icons` (from `assets/B.png`)                    |
| Font              | JetBrains Mono (bundled in `fonts/`)                              |

## Project structure

```
lib/
  main.dart                     # App entry, Firebase init, auth gate, tab shell
  theme.dart                    # Neo-Brutalist design system + PKR money formatting
  currency.dart                 # Currency model + helpers (app is fixed to PKR)
  firebase_options.dart         # Firebase project config (budcut-308d9)
  models/                       # category.dart, transaction.dart, recurring_bill.dart
  services/
    app_state.dart              # Central ChangeNotifier: budgets, CRUD, analysis
    storage_service.dart        # SharedPreferences read/write + clearAll
    seed_data.dart              # Default category/bill templates
  screens/
    login_screen.dart           # Email/password sign in & sign up
    dashboard_screen.dart       # Overview KPIs, charts, progress, recent txns
    weekly_screen.dart          # Current week analysis
    monthly_screen.dart         # Current month analysis + category caps
    quarterly_screen.dart       # Rolling quarter analysis
    custom_range_screen.dart    # Arbitrary date-range analysis
    true_expense_screen.dart    # Flexible money after recurring liabilities
    recurring_bills_screen.dart # Recurring bill manager + auto-log
    category_manager_screen.dart# Budget & categories manager, reset, sign out
  widgets/
    bento.dart                  # BrutButton, BrutIconButton, BentoCard, headers
    charts.dart                 # Bar + donut chart widgets
    modals.dart                 # Quick-add / edit transaction & category modals
    progress.dart               # Budget / cap progress bars
    transaction_list.dart       # Filterable list with edit/delete & CSV export
```

## Getting started

Prerequisites: Flutter SDK, and (for backend auth) a configured Firebase
project.

```bash
flutter pub get
```

The app expects real Firebase configuration. `lib/firebase_options.dart` is
generated for the project `budcut-308d9` (see `.firebaserc` / `firebase.json`).
To point BudCut at your own Firebase project, run:

```bash
firebase login
flutterfire configure
```

and then enable **Email/Password** under _Authentication → Sign-in method_.

### Run

```bash
flutter run            # attaches to a connected device/emulator or Chrome
```

### Build

```bash
flutter build apk      # Android release APK
flutter build appbundle# Android release bundle (Play Store)
flutter build web      # static web build in build/web
```

### Regenerate app icons

```bash
dart run flutter_launcher_icons
```

Icon source is `assets/B.png`; generated icons live in
`android/app/src/main/res/mipmap-*`, `ios/Runner/.../AppIcon.appiconset`, and
`web/icons/`.

## Notes

- **PKR only**: amounts are stored internally in PKR and formatted with
  Indian/Pakistani grouping (`1,23,456`); there is no currency switcher.
- **Fresh install**: starts with the default category/bill templates and a
  zero budget — no fake transactions are seeded. Use _Reset All Data_ in the
  **Categories** tab to start completely empty.
- **Sign out** is at the bottom of the **Budgets & Categories** tab.
