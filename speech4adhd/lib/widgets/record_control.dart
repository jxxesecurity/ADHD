import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Animated mic button: pulse when recording, big and tappable.
class RecordControl extends StatefulWidget {
  const RecordControl({
    super.key,
    required this.onPressed,
    this.size = 120,
    this.isRecording = false,
  });

  final VoidCallback? onPressed;
  final double size;
  final bool isRecording;

  @override
  State<RecordControl> createState() => _RecordControlState();
}

class _RecordControlState extends State<RecordControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isRecording ? AppColors.primary : AppColors.accent;
    // Extra box so pulse scale + shadow don't overflow parent RenderFlex.
    final box = 1.28 * widget.size;
    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final scale = widget.isRecording ? _pulse.value : 1.0;
              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: widget.isRecording ? 20 : 12,
                    spreadRadius: widget.isRecording ? 4 : 2,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.stop_rounded : Icons.mic,
                size: widget.size * 0.45,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
