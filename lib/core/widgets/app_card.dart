import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.icon,
    this.padding = const EdgeInsets.all(AppSpacing.medium),
    this.showBorder = true,
    super.key,
  });

  final Widget child;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: showBorder ? 0 : 2,
      child: Padding(
        padding: padding,
        child: icon == null
            ? child
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSpacing.small + AppSpacing.xSmall),
                  Expanded(child: child),
                ],
              ),
      ),
    );
  }
}
