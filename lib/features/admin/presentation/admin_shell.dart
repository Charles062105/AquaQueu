import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/app_user.dart';
import '../../../services/admin_service.dart';
import '../../../services/product_service.dart';
import '../../products/presentation/product_provider.dart';
import 'admin_provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_orders_screen.dart';
import 'screens/admin_products_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    required this.user,
    required this.adminService,
    required this.productService,
    required this.onLogout,
    this.initialTab = 0,
    super.key,
  });

  final AppUser user;
  final AdminService adminService;
  final ProductService productService;
  final Future<void> Function() onLogout;
  final int initialTab;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _selectedTab = widget.initialTab;
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AdminProvider(
            adminService: widget.adminService,
            adminId: widget.user.uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(widget.productService),
        ),
      ],
      child: Builder(
        builder: (context) {
          final titles = ['Dashboard', 'Orders', 'Products'];
          return Scaffold(
            appBar: AppBar(
              title: Text(titles[_selectedTab]),
              actions: [
                IconButton(
                  tooltip: 'Log out',
                  onPressed: _isLoggingOut
                      ? null
                      : () async {
                          setState(() => _isLoggingOut = true);
                          try {
                            await widget.onLogout();
                          } finally {
                            if (mounted) setState(() => _isLoggingOut = false);
                          }
                        },
                  icon: _isLoggingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                ),
              ],
            ),
            body: IndexedStack(
              index: _selectedTab,
              children: const [
                AdminDashboardScreen(),
                AdminOrdersScreen(),
                AdminProductsScreen(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedTab,
              onDestinationSelected: (index) =>
                  setState(() => _selectedTab = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.water_drop_outlined),
                  selectedIcon: Icon(Icons.water_drop),
                  label: 'Products',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
