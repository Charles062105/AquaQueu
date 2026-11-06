# System Architecture

## Client

- Flutter with Material 3 and feature-oriented screens under `lib/features/`.
- `Navigator` named routes remain the routing mechanism.
- Provider manages authentication, catalog state, the in-memory cart, and the customer order stream.
- `AuthService` wraps Firebase Authentication; `UserService` owns permitted profile reads and updates; product and order services wrap Firestore.
- The signed-in profile role is read from `users/{uid}`. Missing or unrecognized role values default to `customer`; only an exact `admin` role enters `AdminShell`. Customer navigation has no admin entry point and direct admin routes fall back to the customer shell.
- Cart entries contain only product IDs and quantities. `FirestoreOrderService` reads fresh product documents in a transaction, validates the displayed prices and availability, and builds the stored order snapshot.
- The order service uses a Firestore-generated ID as part of `AQ-YYYYMMDD-{autoId}`. The full value is also the document ID, preventing practical collisions through Firestore's auto-ID uniqueness.
- Customer order history queries `customerId` with `createdAt` descending and uses the deployed composite index.
- `FirestoreAdminService` uses Firestore aggregation queries for total, pending, confirmed, delivered, and sales metrics, avoiding downloading order documents for dashboard totals. Sales sum `totalAmount` only where `orderStatus == "Delivered"` and `paymentStatus == "Paid"`. Metrics refresh on demand and after admin mutations.
- Admin order management streams orders ordered by `createdAt` descending and batches customer profile reads in groups of at most 30 IDs so order search can include customer names.
- Admin status mutations use a Firestore transaction with an expected-current-status check. The order update, append-only status history document, and immutable audit record commit together.
- Customer order details subscribe to the order document and its status-history subcollection, so status changes appear without reopening the order. The order list remains newest-first.
- Delivery checkout optionally stores a selected latitude/longitude as Firestore `GeoPoint`. `flutter_map` displays OpenStreetMap tiles with attribution and the AquaQueue package user agent; `geolocator` requests foreground location only after an explanation. The manually entered delivery address remains mandatory.
- Customer and administrator order details show a read-only pin map. Administrators can open the pinned coordinate in an external maps app through `url_launcher`.
- Product creates/edits, payment confirmation, and order status transitions write immutable `adminActions` records atomically with the target change.

## Firebase

- Project: `aquaqueue-af8d3`.
- Firebase Authentication uses email and password.
- Cloud Firestore stores customer profiles, catalog products, and customer orders.
- Firestore Rules are the authorization boundary. Self-registration assigns `customer`; admin roles are assigned manually in Firebase Console.
- No Storage, Cloud Functions, online payments, live rider tracking, background location, or push notifications are used. Map tiles come from OpenStreetMap and need no API key.

## Order policy and trust boundaries

- Delivery fee is defined as `AppConstants.deliveryFee` (30); Firestore rules enforce the same fee. Pickup is free.
- Rules validate customer ownership, product snapshot prices and availability, line totals, subtotal, delivery fee, total, Pending status, and Unpaid status.
- Rules currently accept at most three distinct product entries per order; raise this limit in both the client and rules before expanding the cart.
- Customers can read their own orders but cannot update or delete them. No client-supplied total or current UI state is trusted as the order price.
- Customer profile updates are limited to `fullName`, `phoneNumber`, and `address`; role is protected by rules.
- The order lifecycle is defined by `canTransition` and `allowedNextStatuses` in `lib/models/order.dart`; Firestore Rules mirror the same transition table:
  - Pending → Confirmed or Cancelled
  - Confirmed → Preparing or Cancelled
  - Preparing → Out for Delivery for delivery orders; Delivered for pickups; either may be Cancelled
  - Out for Delivery → Delivered or Cancelled (delivery only)
  - Delivered and Cancelled are final
- Only admins can change order status. Rules require matching server-timestamped status-history and audit writes in the same atomic request, and keep order items, totals, ownership, and creation time immutable.
- Payment confirmation remains a separate Unpaid → Paid update. Customer status history is read-only.
- Admins may create or update validated products and cannot delete them. Product edits do not mutate order item snapshots.
- Admin action records contain `adminId`, action type, target ID, and server timestamp; admins may read them and no client may modify/delete them.
