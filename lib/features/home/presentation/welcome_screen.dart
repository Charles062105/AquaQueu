import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                    vertical: AppSpacing.xLarge,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.darkBlue.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              size: 58,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xLarge),
                          Text(
                            AppConstants.appName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Text(
                            AppConstants.tagline,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.darkBlue,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            AppConstants.welcomeDescription,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xLarge),
                          AppButton(
                            label: 'Get Started',
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.login),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            'A better refill routine starts here.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
