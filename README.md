# AquaQueue

AquaQueue is a Flutter water refilling and delivery booking app foundation.
The customer experience is built around the tagline **Refill. Book. Relax.**

The current customer UI uses local mock data and demonstration-only
authentication, cart, and checkout flows. It does not submit real accounts,
orders, or payments, and it does not connect to Firebase.

## Getting started

```shell
flutter pub get
flutter run
```

Run static analysis and widget tests with:

```shell
flutter analyze
flutter test
```

## Project layout

- `lib/app/` contains app startup, route names, and shared theme configuration.
- `lib/core/` contains shared constants, formatters, and reusable widgets.
- `lib/features/` contains authentication, customer, product, order, and profile
  features.
- `docs/phase-1-report.md` and `docs/phase-2-report.md` document the completed
  foundation and customer interface.

No Firebase or other new third-party dependencies are configured.
