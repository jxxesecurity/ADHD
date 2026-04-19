import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../config/gemini_config.dart';
import '../constants/colors.dart';
import '../services/debate_spark_service.dart';
import '../services/debate_time_feedback.dart';
import '../services/permission_service.dart';
import '../services/spark_voice_service.dart';
import 'record_control.dart';

/// Quick Debate + Spark: STT → Gemini reaction → TTS (no audio file replay).
class DebateSparkPanel extends StatefulWidget {
  const DebateSparkPanel({
    super.key,
    required this.topic,
    required this.agreed,
  });

  final String topic;
  final bool agreed;

  @override
  State<DebateSparkPanel> createState() => _DebateSparkPanelState();
}

enum _DpPhase { idle, listening, thinking, speaking }

class _DebateSparkPanelState extends State<DebateSparkPanel> {
  static const int _maxSeconds = 90;

  final SpeechToText _speech = SpeechToText();
  final SparkVoiceService _voice = SparkVoiceService();

  bool _speechReady = false;
  _DpPhase _phase = _DpPhase.idle;
  String _liveTranscript = '';
  String _sessionLastNonEmpty = '';
  bool _listenSession = false;
  bool _manualStopInProgress = false;
  Completer<String>? _finalWordsCompleter;
  bool _submitting = false;
  DateTime? _listenStartedAt;

  int _secondsLeft = _maxSeconds;
  Timer? _listenTimer;
  bool _warned10 = false;
  bool _warned5 = false;

  String? _sparkReply;
  String? _lastKidLine;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onError: (e) {
        if (!mounted) return;
        final raw = e.errorMsg.trim();
        if (raw.isEmpty) return;
        final m = raw.toLowerCase();
        if (m.contains('no_match') ||
            m.contains('error_speech_timeout') ||
            m.contains('error_listen_failed') ||
            m.contains('error_busy')) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech helper hiccup: $raw'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onStatus: (status) {
        if (!mounted || !_listenSession || _manualStopInProgress) return;
        if (status == 'notListening' || status == 'done') {
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            if (!mounted || !_listenSession || _manualStopInProgress) return;

            final started = _listenStartedAt;
            final elapsed = started != null
                ? DateTime.now().difference(started)
                : Duration.zero;
            const minAutoFinalize = Duration(milliseconds: 2800);
            if (elapsed < minAutoFinalize) {
              if (_rollupTranscript().trim().isNotEmpty) {
                unawaited(_onListenEnded());
              }
              return;
            }

            if (_speech.isListening) {
              return;
            }
            unawaited(_onListenEnded());
          });
        }
      },
    );
    if (mounted) setState(() => _speechReady = ok);
  }

  void _cancelListenTimer() {
    _listenTimer?.cancel();
    _listenTimer = null;
  }

  void _startListenTimer() {
    _cancelListenTimer();
    _secondsLeft = _maxSeconds;
    _warned10 = false;
    _warned5 = false;
    _listenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _phase != _DpPhase.listening) {
        _cancelListenTimer();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft == 10 && !_warned10) {
          _warned10 = true;
          playDebateAlmostUpCue();
        }
        if (_secondsLeft == 5 && !_warned5) {
          _warned5 = true;
          playDebateAlmostUpCue(urgent: true);
        }
        if (_secondsLeft <= 0) {
          _cancelListenTimer();
          unawaited(_stopListeningManually());
        }
      });
    });
  }

  @override
  void dispose() {
    _cancelListenTimer();
    _speech.stop();
    unawaited(_voice.stop());
    super.dispose();
  }

  String _rollupTranscript() {
    final live = _liveTranscript.trim();
    if (live.isNotEmpty) return live;
    final last = _speech.lastRecognizedWords.trim();
    if (last.isNotEmpty) return last;
    return _sessionLastNonEmpty;
  }

  Future<void> _onMicPressed() async {
    if (!hasGeminiApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a Gemini key: --dart-define=GEMINI_API_KEY=…',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_phase == _DpPhase.thinking) return;

    if (_phase == _DpPhase.speaking) {
      await _voice.stop();
      if (mounted) setState(() => _phase = _DpPhase.idle);
      return;
    }

    if (_phase == _DpPhase.listening) {
      await _stopListeningManually();
      return;
    }

    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not ready yet — try again!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final mic = await PermissionService.requestMicrophone();
    if (!mic && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Microphone is needed. Check Settings.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _phase = _DpPhase.listening;
      _liveTranscript = '';
      _sessionLastNonEmpty = '';
      _listenSession = true;
      _sparkReply = null;
    });
    _finalWordsCompleter = null;

    await _voice.stop();
    _listenStartedAt = DateTime.now();

    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        final words = r.recognizedWords;
        setState(() => _liveTranscript = words);
        final t = words.trim();
        if (t.isNotEmpty) {
          _sessionLastNonEmpty = t;
        }
        if (r.finalResult) {
          final c = _finalWordsCompleter;
          if (c != null && !c.isCompleted) {
            c.complete(t.isNotEmpty ? t : _sessionLastNonEmpty);
          }
        }
      },
      listenFor: const Duration(seconds: 90),
      pauseFor: const Duration(seconds: 12),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
    if (!mounted) return;
    _startListenTimer();
  }

  Future<void> _stopListeningManually() async {
    _manualStopInProgress = true;
    _cancelListenTimer();
    _finalWordsCompleter = Completer<String>();
    final c = _finalWordsCompleter;
    try {
      await _speech.stop();
      var text = '';
      if (c != null) {
        try {
          text = await c.future.timeout(
            const Duration(milliseconds: 2600),
            onTimeout: () => '',
          );
        } catch (_) {
          text = '';
        }
      }
      if (text.trim().isEmpty) {
        text = _rollupTranscript();
      }
      await _onListenEnded(preferredText: text.trim());
    } finally {
      _manualStopInProgress = false;
      _finalWordsCompleter = null;
    }
  }

  Future<void> _onListenEnded({String? preferredText}) async {
    if (!_listenSession || _submitting) return;
    _listenSession = false;
    _listenStartedAt = null;
    if (!mounted) return;

    final said = (preferredText != null && preferredText.isNotEmpty)
        ? preferredText
        : _rollupTranscript();
    setState(() {
      _phase = _DpPhase.idle;
      _liveTranscript = '';
      _sessionLastNonEmpty = '';
    });

    if (said.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("I didn't catch that — tap the mic and try again! 🎤"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await _sendToSpark(said);
  }

  Future<void> _sendToSpark(String said) async {
    _submitting = true;
    setState(() {
      _lastKidLine = said;
      _phase = _DpPhase.thinking;
    });

    try {
      final reply = await DebateSparkService.react(
        topic: widget.topic,
        agreed: widget.agreed,
        whatTheySaid: said,
      );
      if (!mounted) return;
      setState(() {
        _sparkReply = reply;
        _phase = _DpPhase.speaking;
      });
      await _voice.init();
      await _voice.speak(reply);
    } on DebateSparkException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      _submitting = false;
      if (mounted) setState(() => _phase = _DpPhase.idle);
    }
  }

  String get _statusLine {
    switch (_phase) {
      case _DpPhase.idle:
        if (!hasGeminiApiKey) return 'Add a Gemini key for Buddy.';
        if (_sparkReply != null) {
          return 'Tap the mic to give another reason! 🎤';
        }
        return 'Tap the mic — Buddy will answer back kindly! 🎤';
      case _DpPhase.listening:
        return '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')} left — keep going!';
      case _DpPhase.thinking:
        return 'Buddy is thinking… 🤔';
      case _DpPhase.speaking:
        return 'Buddy is talking — tap mic to stop';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasGeminiApiKey)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Buddy needs a Gemini API key (same as Let’s Chat).',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        if (_phase == _DpPhase.listening)
          Text(
            'Up to 1:30 — Buddy will cheer you on!',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        if (_phase == _DpPhase.listening && _liveTranscript.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _liveTranscript,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (_lastKidLine != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _lastKidLine!,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
        if (_sparkReply != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.9),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🦊 ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      _sparkReply!,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Center(
          child: RecordControl(
            onPressed: (_phase == _DpPhase.thinking && !_listenSession) ? null : _onMicPressed,
            size: 100,
            isRecording: _phase == _DpPhase.listening,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _statusLine,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
