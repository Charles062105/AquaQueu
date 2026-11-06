# Development Roadmap

## Completed

- **Phase 1:** Flutter foundation, shared theme and widgets, named-route navigation, and welcome screen.
- **Phase 2:** Customer UI with illustrative products and prices, in-memory cart and sample orders, checkout flow, and profile screens.
- **Phase 3:** Firebase Authentication, customer profile reads and permitted updates, Firestore product reads, deployed Firestore Rules, and emulator-verified authorization tests.
- **Phase 4:** Provider-backed in-memory cart, transaction-based Firestore order creation and customer history/details, deployed order rules/index, and passing local emulator rule tests. Live-account manual ordering remains unverified pending a disposable test account.
- **Phase 5:** Role-gated admin dashboard, product editing (no deletion or image uploads), order search/filter/details, payment confirmation, immutable admin action audit records, and expanded Firestore rules.
- **Phase 6:** Admin-only order lifecycle transitions, append-only server-timestamped status history and audit records, customer live order tracking, and transition-rule emulator coverage. Live account walkthrough remains pending test credentials.
- **Phase 7:** Optional delivery location pins using OpenStreetMap, foreground-only current-location selection, order detail maps, and Firestore GeoPoint validation. Live API 34 mock-location walkthrough remains to be verified.
- **Emulator testing:** Local Auth and Firestore integration setup, deterministic admin/customer/product fixtures, and registration/order/status/authorization integration tests are documented in [emulator-testing.md](./emulator-testing.md).

## Phase 3 — Authentication and catalog foundation

- Completed: Firebase configured for Android package `com.aquaqueue.app` in project `aquaqueue-af8d3`.
- Completed: email/password authentication and Provider-based auth state; login and registration use Firebase Authentication.
- Completed: customer profile documents use a server timestamp; Firestore Rules enforce customer-only self-registration.
- Completed: read and edit the signed-in customer’s permitted profile fields.
- Completed: read products from Firestore; a Firebase Console seed procedure is documented for sample products.
- Completed: deployed and emulator-tested Firestore Security Rules. Keep order persistence on mock services until Phase 4.

## Phase 4 — Customer order persistence (implemented)

- Implement authenticated Firestore order creation and customer-scoped order reads.
- Validate order totals, status, product snapshots, and ownership in Security Rules.
- Emulator tests pass; rules and the order-history index are deployed.
- Complete a live-account API 34 walkthrough with a disposable test account before release.

## Phase 5 — Administrator dashboard (implemented)

- Dashboard sales count only orders both Paid and Delivered; metrics use server-side Firestore aggregation queries.
- Admins can confirm Pending orders and mark Unpaid orders as Paid; all other status transitions remain prohibited until Phase 6.
- Admin product edits disable availability rather than deleting records, preserving purchase-time order snapshots.
- Order review and product mutations create immutable `adminActions` records in atomic writes.

## Phase 6 — Order lifecycle and tracking (implemented)

- The Dart transition model and Firestore Rules enforce the same allowed transition table; only admins may update status.
- Every transition writes the order status, append-only `statusHistory` entry, and `adminActions` record in one transaction using server timestamps.
- The customer order detail subscribes to status and history changes; pickup and delivery show different progress steps. GPS, live maps, notifications, online payments, Cloud Functions, and Storage remain excluded.
- Rules emulator tests cover every allowed transition and required blocked cases. Manual API 34 testing needs disposable admin and customer accounts.

## Phase 7 — Delivery location pins (implemented)

- Delivery checkout retains the required text address and optionally attaches a pin selected on the map or using foreground current location after user explanation/permission.
- OSM tiles include application user-agent and visible attribution; no API key, background location, GPS rider tracking, or live map is used.
- Firestore stores the pin as an optional GeoPoint on delivery orders only; rules validate coordinate bounds and prevent later changes.
- `flutter_map` renders OSM tiles, `latlong2` provides map coordinate types, `geolocator` accesses the device's current position, and `url_launcher` opens the map attribution and administrator's coordinate in an external maps app.
- Manual API 34 permission/location testing requires a responsive emulator and a disposable test account.
