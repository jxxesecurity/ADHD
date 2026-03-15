import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Fun cartoon mascot with a gentle bounce animation.
/// Can be swapped for a Lottie asset later via assets.
class AnimatedMascot extends StatefulWidget {
  const AnimatedMascot({
    super.key,
    this.size = 120,
  });

  final double size;

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: child,
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _MascotPainter(),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final bodyPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    final outlinePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, outlinePaint);

    final eyeRadius = radius * 0.2;
    final leftEye = Offset(center.dx - radius * 0.35, center.dy - radius * 0.2);
    final rightEye = Offset(center.dx + radius * 0.35, center.dy - radius * 0.2);
    final eyePaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(leftEye, eyeRadius, eyePaint);
    canvas.drawCircle(rightEye, eyeRadius, eyePaint);

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
