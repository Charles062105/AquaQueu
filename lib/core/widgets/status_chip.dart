import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Chip(
      label: Text(label),
      side: BorderSide(color: effectiveColor.withValues(alpha: 0.3)),
      backgroundColor: effectiveColor.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: effectiveColor, fontWeight: FontWeight.w600),
    );
  }
}
