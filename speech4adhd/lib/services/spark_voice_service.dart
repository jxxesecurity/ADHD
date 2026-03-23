import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech tuned for short, friendly lines (Spark).
class SparkVoiceService {
  SparkVoiceService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await _tts.setLanguage('en-US');
    await _tts.awaitSpeakCompletion(true);
    // Slightly slower + brighter for kids.
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.05);
    await _tts.setVolume(1.0);
    _ready = true;
  }

  /// Speaks [text] and completes when TTS finishes (or stops).
  Future<void> speak(String text) async {
    await init();
    await stop();
    if (text.trim().isEmpty) return;

    final completer = Completer<void>();
    void completeOnce() {
      if (!completer.isCompleted) completer.complete();
    }

    _tts.setCompletionHandler(completeOnce);
    _tts.setErrorHandler((msg) => completeOnce());

    await _tts.speak(text);
    await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: completeOnce,
    );
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
