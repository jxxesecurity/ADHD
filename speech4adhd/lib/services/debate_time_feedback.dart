import 'package:flutter/services.dart';

/// Haptic + system “click” when debate time is almost up (classic + Spark listen).
void playDebateAlmostUpCue({bool urgent = false}) {
  if (urgent) {
    HapticFeedback.heavyImpact();
  } else {
    HapticFeedback.mediumImpact();
  }
  SystemSound.play(SystemSoundType.click);
}
