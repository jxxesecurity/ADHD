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
          padding: padding ?? const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (icon != null) ...[
              SizedBox(
                width: 24,
                height: 24,
                child: Icon(icon, size: 22),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
