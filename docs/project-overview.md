# AquaQueue Project Overview

AquaQueue is a Flutter Android customer app for browsing water products and arranging pickup or delivery. Its tagline is “Refill. Book. Relax.”

## Current state

Phases 1–2 provide the Material 3 UI, named Navigator routes, reusable widgets, and customer screens. Phase 3 adds Firebase email/password authentication, customer profiles, and Firestore product reads. Phase 4 adds an in-memory Provider cart and Firestore order creation, history, and details. Phase 5 adds a role-gated administrator dashboard and product management. Phase 6 adds administrator-only status transitions, append-only status history and audit entries, and customer tracking. Phase 7 adds optional delivery map pins on orders.

## Firebase configuration

Use Firebase project `aquaqueue-af8d3` and Android application ID `com.aquaqueue.app`. Firestore rules and indexes cover customer ordering, administrator order status/payment updates, product management, and immutable audit records. Admin accounts are created by manually setting `users/{uid}.role` to `admin` in Firebase Console.

## Product constraints

- Customer and administrator roles are distinct; administrators are assigned manually in Firebase Console.
- The cart stores product IDs and quantities; current product data is revalidated at submission.
- The delivery fee is 30 for delivery and 0 for pickup. Firestore rules mirror this value.
- Recorded sales count only orders with both `orderStatus == "Delivered"` and `paymentStatus == "Paid"`.
- Dashboard metrics use Firestore count/sum aggregation queries; the order list streams orders newest-first and searches the loaded order/customer records.
- Orders are limited to three distinct products until the rules are expanded to validate larger item lists.
- Order states follow the lifecycle rules in `lib/models/order.dart`; Firestore rules mirror and enforce those transitions. Customers can view a live status timeline but cannot change statuses.
- Each status change appends `orders/{orderId}/statusHistory/{statusKey}` and an immutable `adminActions` document in the same transaction.
- Delivery orders may include a GeoPoint selected on an OpenStreetMap pin picker or from current location; the typed street address remains required. Pickup orders never store coordinates.
- Product images use optional external HTTP(S) URLs; there is no upload flow.
- No Firebase Storage, Cloud Functions, live rider GPS tracking, or online payments.
- No service-account keys, administrator credentials, or other secrets are stored in the client or repository.
- Live-account Phase 6 verification still requires disposable admin and customer test accounts.
