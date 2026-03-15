import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Large, colorful, ADHD-friendly button: big, rounded, high-contrast.
class BigFriendlyButton extends StatelessWidget {
  const BigFriendlyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor = AppColors.white,
    this.icon,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? AppColors.primary;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foregroundColor,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 32),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
