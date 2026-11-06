import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/registration_screen.dart';
import '../features/authentication/presentation/auth_provider.dart';
import '../features/customer/presentation/customer_shell.dart';
import '../features/admin/presentation/admin_shell.dart';
import '../features/home/presentation/welcome_screen.dart';
import '../features/customer/presentation/screens/product_details_screen.dart';
import '../features/orders/presentation/screens/order_details_screen.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import '../core/widgets/app_loading.dart';
import 'routes.dart';
import 'theme.dart';

class AquaQueueApp extends StatelessWidget {
  const AquaQueueApp({
    required this.authService,
    required this.userService,
    required this.productService,
    required this.orderService,
    required this.adminService,
    super.key,
  });

  final AuthService authService;
  final UserService userService;
  final ProductService productService;
  final OrderService orderService;
  final AdminService adminService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(authService: authService, userService: userService),
        ),
        Provider<UserService>.value(value: userService),
        Provider<ProductService>.value(value: productService),
        Provider<OrderService>.value(value: orderService),
        Provider<AdminService>.value(value: adminService),
      ],
      child: MaterialApp(
        title: 'AquaQueue',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
        onUnknownRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const UnknownRouteScreen()),
        routes: {
          AppRoutes.splash: (_) => const WelcomeScreen(),
          AppRoutes.login: (context) => LoginScreen(
            onCreateAccount: () =>
                Navigator.of(context).pushNamed(AppRoutes.register),
          ),
          AppRoutes.register: (context) => RegistrationScreen(
            onBackToLogin: () => Navigator.of(context).pop(),
          ),
          AppRoutes.home: (_) => const AuthGate(),
          AppRoutes.products: (_) => const AuthGate(initialTab: 1),
          AppRoutes.cart: (_) => const AuthGate(initialTab: 2),
          AppRoutes.checkout: (_) => const AuthGate(initialTab: 2),
          AppRoutes.orders: (_) => const AuthGate(initialTab: 3),
          AppRoutes.profile: (_) => const AuthGate(initialTab: 4),
          AppRoutes.admin: (_) => const AuthGate(adminOnly: true),
          AppRoutes.adminOrders: (_) =>
              const AuthGate(adminOnly: true, initialAdminTab: 1),
          AppRoutes.adminProducts: (_) =>
              const AuthGate(adminOnly: true, initialAdminTab: 2),
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.productDetails) {
            final arguments = settings.arguments;
            if (arguments is ProductDetailsRouteArguments) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => ProductDetailsScreen(
                  product: arguments.product,
                  onAddToCart: arguments.onAddToCart,
                  onCheckout: arguments.onCheckout,
                ),
              );
            }
          }
          if (settings.name == AppRoutes.orderDetails) {
            final arguments = settings.arguments;
            if (arguments is OrderDetailsRouteArguments) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (routeContext) => OrderDetailsScreen(
                  order: arguments.order,
                  orderService: routeContext.read<OrderService>(),
                ),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    this.initialTab = 0,
    this.adminOnly = false,
    this.initialAdminTab = 0,
    super.key,
  });

  final int initialTab;
  final bool adminOnly;
  final int initialAdminTab;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(
        body: AppLoadingIndicator.fullScreen(
          message: 'Checking your account...',
        ),
      );
    }
    if (!auth.isAuthenticated) {
      return LoginScreen(
        onCreateAccount: () =>
            Navigator.of(context).pushNamed(AppRoutes.register),
      );
    }
    if (auth.profileError != null) {
      return Scaffold(
        body: AppErrorState(
          message: auth.profileError!,
          onRetry: auth.reloadProfile,
        ),
      );
    }
    final profile = auth.profile;
    if (profile == null) {
      return const Scaffold(
        body: AppLoadingIndicator.fullScreen(
          message: 'Loading your customer profile...',
        ),
      );
    }
    if (profile.role == 'admin') {
      return AdminShell(
        user: profile,
        adminService: context.read<AdminService>(),
        productService: context.read<ProductService>(),
        onLogout: auth.logout,
        initialTab: initialAdminTab,
      );
    }
    return CustomerShell(
      user: profile,
      initialTab: adminOnly ? 0 : initialTab,
      productService: context.read<ProductService>(),
      orderService: context.read<OrderService>(),
    );
  }
}
