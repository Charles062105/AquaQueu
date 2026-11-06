# AquaQueue Phase 2 Report

## 1. Screens implemented

- Welcome and mock customer login.
- Customer registration with required-field, email, password-length, and
  password-confirmation validation.
- Customer home with greeting, welcome banner, service shortcuts, featured
  products, recent sample orders, and bottom navigation.
- Product catalog with local search and category filters.
- Product details with availability, quantity selection, live subtotal, and
  add-to-cart/checkout actions.
- Checkout with order summary, quantity changes, item removal, pickup/delivery
  selection, delivery information, preferred date and time, payment options,
  subtotal, delivery fee, total, and a demonstration confirmation.
- Order history with status filters, sample orders, and empty-state handling.
- Order details with line items, delivery/payment details, and a status timeline
  or cancelled state.
- Customer profile with temporary local personal-information/address editing,
  orders/about links, and logout.

## 2. Components created

- `AppLogo` for a consistent AquaQueue water-drop mark.
- `ProductCard` for consistent catalog and featured-product presentation.
- `AppFormatters` for shared Philippine peso and date formatting.
- Existing Phase 1 `AppButton`, `AppTextField`, `AppCard`, and `AppEmptyState`
  components are reused.

## 3. Files created

- `lib/core/utils/app_formatters.dart`
- `lib/core/widgets/app_logo.dart`
- `lib/features/authentication/presentation/screens/login_screen.dart`
- `lib/features/authentication/presentation/screens/registration_screen.dart`
- `lib/features/customer/presentation/customer_shell.dart`
- `lib/features/customer/presentation/screens/checkout_screen.dart`
- `lib/features/customer/presentation/screens/home_screen.dart`
- `lib/features/customer/presentation/screens/product_catalog_screen.dart`
- `lib/features/customer/presentation/screens/product_details_screen.dart`
- `lib/features/customer/presentation/widgets/product_card.dart`
- `lib/features/orders/data/mock_orders.dart`
- `lib/features/orders/models/order_model.dart`
- `lib/features/orders/presentation/screens/order_details_screen.dart`
- `lib/features/orders/presentation/screens/orders_screen.dart`
- `lib/features/products/data/mock_products.dart`
- `lib/features/products/models/product_model.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `docs/phase-2-report.md`

## 4. Files modified

- `lib/app/app.dart` registers the customer-facing routes.
- `lib/core/constants/app_constants.dart` adds the illustrative delivery fee.
- `lib/features/home/presentation/welcome_screen.dart` opens the login flow.
- `test/widget_test.dart` covers authentication, products, cart/checkout,
  orders, profile, and responsive screen sizes.
- `README.md` documents the current project scope and commands.

## 5. Navigation structure

- Welcome `/splash` opens `/login`.
- Login validates locally and continues to `/home`.
- Login opens `/register`; registration returns to login after demo completion.
- `/home`, `/products`, `/orders`, and `/profile` open the customer shell at the
  corresponding bottom-navigation tab.
- The four bottom tabs use an `IndexedStack` to preserve screen state.
- Product cards open product details; details can add to cart or continue to
  checkout.
- Checkout shows a local confirmation, and order cards open order details.
- Logout returns to login.
- The admin route name remains a Phase 1 placeholder and is not part of this
  customer phase.

## 6. Mock data structure

- `MockProducts` contains the three illustrative sample water products and
  prices: purified 5-gallon ₱50, mineral 5-gallon ₱60, and purified 1-gallon
  ₱25.
- `MockOrders` contains sample orders covering pending, confirmed, preparing,
  out-for-delivery, delivered, and cancelled statuses.
- Models define products, categories, order lines, order status, and customer
  orders separately from presentation screens.

## 7. UI interactions implemented

- Local mock login and registration validation; no account details are stored.
- Remember-me checkbox state and a placeholder forgot-password message.
- Local product search and category chips.
- Cart count and quantity updates; checkout line items can be adjusted or
  removed, with live subtotal and total calculations.
- Pickup disables delivery information and has no delivery fee; home delivery
  uses the configurable illustrative ₱30 fee.
- Home-delivery recipient/contact/address fields, date, and time are validated.
- Payment method selection and demonstration-only order confirmation.
- Sample order status filters, detail navigation, order progress timeline, and
  cancelled state.
- Temporary profile/address editing, about information, and logout.

## 8. Testing results

- `flutter pub get` completed successfully; no dependency was added for this
  phase.
- `flutter analyze` completed with **No issues found**.
- `flutter test --reporter expanded` passed all **11 widget tests**, covering
  login, registration validation, product filtering, details/subtotals, cart
  quantity and removal, pickup/delivery fee behavior, delivery validation,
  orders, profile editing, and 360×800, 390×844, and 412×915 logical layouts.
- `flutter devices` detected the Android 17 emulator (1080×2400 physical,
  approximately 411×914 logical pixels). `flutter run -d emulator-5554
  --no-pub` built and launched AquaQueue; emulator captures showed the welcome
  and login screens.
- Dart runtime inspection found no runtime errors after launch. A subsequent
  rapid ADB text-entry attempt triggered an Android input-dispatch ANR; the app
  was force-stopped and relaunched for a clean final emulator launch. Full
  customer navigation and forms are covered by the passing widget tests.

## 9. Known issues

- Authentication, profile edits, orders, and checkout are demonstration-only
  local UI state and are not persistent.
- Product images use built-in icon placeholders; no product photography/assets
  were supplied.
- Preferred delivery date/time are demonstrated locally and are not sent to a
  service.
- `/admin` and remaining later-phase backend services are intentionally
  unimplemented.
- Rapid scripted text entry caused an emulator input-dispatch ANR once. It did
  not produce a Dart runtime error; the emulator was relaunched and the login
  and navigation flows passed widget tests.

## 10. Remaining features

- Firebase Authentication, Firestore, and Storage integration.
- Persistent customer accounts and order submission.
- Real payment processing and real-time order status updates.
- Administrator dashboard and management workflows.
- GPS tracking and push notifications.

These features are outside Phase 2 scope.
