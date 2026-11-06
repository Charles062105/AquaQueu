import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 76.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lightBlue,
        borderRadius: BorderRadius.circular(compact ? 14 : 24),
      ),
      child: Icon(
        Icons.water_drop_rounded,
        color: AppColors.primaryBlue,
        size: compact ? 25 : 42,
      ),
    );
  }
}
