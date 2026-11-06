# One-time sample product seed

The customer catalog reads Firestore collection `products`. To seed the three illustrative products once, use the Firebase Console for project `aquaqueue-af8d3`:

1. In Authentication, create or locate the administrator account you will use.
2. In Firestore Data, create `users/{admin-uid}` for that account and set its `role` to `admin`. This role assignment is intentionally performed manually in the trusted console, never by client registration.
3. In Firestore Data, create these three available products in `products`:

| Document ID | `name` | `description` | `price` | `category` | `available` |
|---|---|---|---:|---|---|
| `purified-5-gallon` | `5-Gallon Purified Water` | `Clean, refreshing purified water for your home or office.` | `50` | `purified` | `true` |
| `mineral-5-gallon` | `5-Gallon Mineral Water` | `Refreshing mineral water with a crisp, balanced taste.` | `60` | `mineral` | `true` |
| `purified-1-gallon` | `1-Gallon Purified Water` | `Convenient purified water for smaller households.` | `25` | `purified` | `true` |

Use numeric fields for `price` and boolean for `available`; add `createdAt` and `updatedAt` as Firestore timestamps. These are illustrative values only, not production prices. Firestore Security Rules permit product writes only to admins.

After Phase 5, administrators can create and edit products in the app. Product image URLs are optional external HTTP(S) links; the app does not upload images or use Firebase Storage. Existing orders retain their purchase-time product name and price snapshots after product edits or disabling.

To preserve the catalog's unavailable-product example, optionally add `mineral-1-gallon` with name `1-Gallon Mineral Water`, description `A sample item that is temporarily unavailable.`, numeric price `30`, category `mineral`, and `available: false`.

## Rules test

With the Firebase CLI and Node.js installed, start the local Auth and Firestore emulators in one terminal:

```powershell
firebase emulators:start --only auth,firestore --project demo-aquaqueue
```

In another terminal, run `node --test test/firestore_rules_test.mjs`. The test uses emulator-only accounts and data; it does not connect to production.
