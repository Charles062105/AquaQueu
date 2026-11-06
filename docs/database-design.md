# Database Design

Firestore uses the following top-level collections. User document IDs are Firebase Auth UIDs. Order IDs are readable order numbers containing a date and Firestore-generated auto-ID.

## `users/{uid}`

```text
fullName: string
email: string
phoneNumber: string
address: string
role: "customer" | "admin"
createdAt: timestamp
```

Self-registration creates a customer document with `createdAt` set by a server timestamp. Customers can read their own document and update only `fullName`, `phoneNumber`, and `address`. A customer cannot set or change `role`. Admin documents are assigned manually in Firebase Console.

## `products/{productId}`

```text
name: string
description: string
price: number
category: string
available: boolean
createdAt: timestamp
updatedAt: timestamp
imageUrl: string | null             // optional external HTTP(S) URL
```

Signed-in users can read products; only admins can write them. Three illustrative catalog products may be seeded with a one-time development script or console procedure; seed values are not live inventory or production prices.

Product documents are created and edited through the administrator UI. Availability is toggled off instead of deleting a product. Edits do not affect existing order item snapshots.

## `orders/{orderId}`

```text
orderNumber: string                 // same as document ID
customerId: string                  // Firebase Auth UID
items: list<{
  productId: string,
  productName: string               // purchase-time snapshot
  unitPrice: number                 // purchase-time snapshot
  quantity: integer
  lineTotal: number
}>
deliveryType: "pickup" | "delivery"
deliveryAddress: string | null
preferredDate: string | null
preferredTime: string | null
deliveryLocation: GeoPoint            // optional; delivery orders only
subtotal: number
deliveryFee: number
totalAmount: number
paymentMethod: "Cash on Delivery" | "Cash on Pickup"
paymentStatus: "Unpaid" | "Paid"
orderStatus: string                  // initially Pending; admin lifecycle
createdAt: timestamp
statusUpdatedAt: timestamp          // most recent admin status transition
confirmedAt: timestamp              // set on Pending -> Confirmed
paidAt: timestamp                   // set on Unpaid -> Paid
```

Order creation reads product documents inside a Firestore transaction. A missing, unavailable, repriced, or unsupported product causes a clear failure; the cart is retained. The purchase-time item snapshot is used by order details and is not recalculated from today's catalog.

The delivery fee is `AppConstants.deliveryFee` (30) for delivery and 0 for pickup; `firestore.rules` independently enforces the same values. Rules currently validate up to three distinct item entries per order. The client generates `AQ-YYYYMMDD-{Firestore auto-ID}` before submission and uses it as both order number and document ID. A failed retry reuses this ID; the transaction returns an existing matching order rather than creating a duplicate and rejects a conflicting reuse.

Customers can create only their own orders, initially `Pending` and `Unpaid`, and read only their own records. Customers cannot update or delete orders. Admins can read all orders and update status only through the lifecycle transition table in `lib/models/order.dart` and the matching Firestore Rules. Pickup orders never use `Out for Delivery`; `Delivered` and `Cancelled` are final. Payment confirmation remains `Unpaid` to `Paid` with `paidAt == request.time`. Item snapshots, totals, ownership, and creation time cannot change.

The optional `deliveryLocation` is stored only when it is a valid GeoPoint on a delivery order. It is not stored for pickup, and permitted order updates cannot change it after creation. Delivery address text remains required whether or not a map pin is supplied.

### `orders/{orderId}/statusHistory/{statusKey}`

```text
status: string                      // destination status
changedAt: timestamp                // server timestamp
changedBy: string                   // administrator UID
```

Status history entries are append-only and keyed by the unique destination status (`pending` is represented by order creation time). A status update is accepted only when the matching history entry and `adminActions` record are written atomically with the order update. Customers can read history for their own orders; only admins can append it.

The customer history composite index and admin dashboard status/payment/total index are deployed. Status history uses Firestore's default single-field index on `changedAt`.

## `adminActions/{actionId}`

```text
adminId: string
action: "order_status_changed" | "payment_confirmed" | "product_created" | "product_edited"
targetId: string
status: string                       // included for order_status_changed
createdAt: timestamp
```

The admin client creates this audit document atomically with its corresponding order, payment, or product mutation. Admins can read the audit collection. Updates and deletes are denied for everyone.

## Dashboard metrics

Firestore aggregation queries compute all-order, Pending, Confirmed, and Delivered counts without downloading the orders. Recorded sales are `SUM(totalAmount)` only for documents where `orderStatus == "Delivered"` **and** `paymentStatus == "Paid"`; unpaid, cancelled, and other incomplete orders contribute nothing.
