import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const textTheme = TextTheme(
    displaySmall: TextStyle(
      color: AppColors.primaryText,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.8,
    ),
    headlineSmall: TextStyle(
      color: AppColors.primaryText,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      color: AppColors.primaryText,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      color: AppColors.primaryText,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      color: AppColors.primaryText,
      fontSize: 16,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      color: AppColors.secondaryText,
      fontSize: 14,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      color: AppColors.secondaryText,
      fontSize: 12,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    labelMedium: TextStyle(
      color: AppColors.secondaryText,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
  );
}
