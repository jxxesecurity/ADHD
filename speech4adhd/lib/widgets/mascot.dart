import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Simple cartoon character widget (painted shape).
/// Placeholder for a friendly mascot; can be replaced with an image asset later.
class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    this.size = 120,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MascotPainter(),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Body (rounded blob)
    final bodyPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, outlinePaint);

    // Eyes
    final eyeRadius = radius * 0.2;
    final leftEye = Offset(center.dx - radius * 0.35, center.dy - radius * 0.2);
    final rightEye = Offset(center.dx + radius * 0.35, center.dy - radius * 0.2);
    final eyePaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(leftEye, eyeRadius, eyePaint);
    canvas.drawCircle(rightEye, eyeRadius, eyePaint);

    // Smile
    final smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.2),
      width: radius * 0.8,
      height: radius * 0.6,
    );
    final smilePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(smileRect, 0.2 * 3.14159, 0.8 * 3.14159, false, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
