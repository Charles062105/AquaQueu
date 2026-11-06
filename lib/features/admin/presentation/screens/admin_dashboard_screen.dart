import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../admin_provider.dart';
import '../widgets/admin_stat_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isDashboardLoading && admin.stats == null) {
          return const AppLoadingIndicator.fullScreen(
            message: 'Loading dashboard...',
          );
        }
        if (admin.dashboardError != null && admin.stats == null) {
          return AppErrorState(
            message: admin.dashboardError!,
            onRetry: admin.refreshDashboard,
          );
        }
        final stats = admin.stats;
        if (stats == null) {
          return AppEmptyState(
            title: 'Dashboard unavailable',
            message: 'Refresh to load the latest order summary.',
            icon: Icons.dashboard_outlined,
            actionLabel: 'Retry',
            onAction: admin.refreshDashboard,
          );
        }
        if (stats.totalOrders == 0) {
          return RefreshIndicator(
            onRefresh: admin.refreshDashboard,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: [
                const SizedBox(height: AppSpacing.xxLarge),
                const AppEmptyState(
                  title: 'No orders to summarize yet',
                  message:
                      'Dashboard totals will appear after customers order.',
                  icon: Icons.dashboard_outlined,
                ),
                OutlinedButton.icon(
                  onPressed: admin.isDashboardLoading
                      ? null
                      : admin.refreshDashboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh summary'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: admin.refreshDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.medium),
            children: [
              Text(
                'Welcome, admin',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'A summary of all recorded customer orders.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (admin.dashboardError != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  admin.dashboardError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 3 : 2;
                  final width =
                      (constraints.maxWidth -
                          (AppSpacing.small * (columns - 1))) /
                      columns;
                  return Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      SizedBox(
                        width: width,
                        child: AdminStatCard(
                          label: 'Total orders',
                          value: '${stats.totalOrders}',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AdminStatCard(
                          label: 'Pending',
                          value: '${stats.pendingOrders}',
                          icon: Icons.hourglass_top_rounded,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AdminStatCard(
                          label: 'Confirmed',
                          value: '${stats.confirmedOrders}',
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AdminStatCard(
                          label: 'Completed',
                          value: '${stats.completedOrders}',
                          icon: Icons.task_alt_rounded,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AdminStatCard(
                          label: 'Recorded sales',
                          value: AppFormatters.currency(
                            stats.totalRecordedSales,
                          ),
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'Recorded sales include only orders marked Paid and Delivered. '
                'Unpaid, cancelled, and incomplete orders are excluded.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.medium),
              OutlinedButton.icon(
                onPressed: admin.isDashboardLoading
                    ? null
                    : admin.refreshDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh summary'),
              ),
            ],
          ),
        );
      },
    );
  }
}
