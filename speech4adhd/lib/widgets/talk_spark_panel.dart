import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../config/gemini_config.dart';
import '../constants/colors.dart';
import '../constants/spark_ai_prompt.dart';
import '../services/permission_service.dart';
import '../services/spark_chat_service.dart';
import '../services/spark_voice_service.dart';
import 'record_control.dart';

/// ADHD-friendly chat UI: Buddy (AI) + kid bubbles, mic, STT → Gemini → TTS.
class TalkSparkPanel extends StatefulWidget {
  const TalkSparkPanel({super.key});

  @override
  State<TalkSparkPanel> createState() => _TalkSparkPanelState();
}

enum _SparkPhase { idle, listening, thinking, speaking }

class _Bubble {
  _Bubble({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}

class _TalkSparkPanelState extends State<TalkSparkPanel>
    with SingleTickerProviderStateMixin {
  final List<_Bubble> _bubbles = [];
  final ScrollController _scroll = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final SparkVoiceService _voice = SparkVoiceService();

  SparkChatService? _chat;
  bool _speechReady = false;
  _SparkPhase _phase = _SparkPhase.idle;
  String _liveTranscript = '';
  String _sessionLastNonEmpty = '';
  bool _listenSession = false;
  bool _manualStopInProgress = false;
  Completer<String>? _finalWordsCompleter;
  bool _submitting = false;
  DateTime? _listenStartedAt;

  late AnimationController _avatarBreath;
  late String _openingLine;

  @override
  void initState() {
    super.initState();
    _openingLine = SparkAiPrompt.randomOpening();
    _avatarBreath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _bubbles.add(_Bubble(isUser: false, text: _openingLine));
    _initSpeech();
    _resetChatService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      if (hasGeminiApiKey) {
        unawaited(_speakOpeningIfPossible());
      }
    });
  }

  Future<void> _speakOpeningIfPossible() async {
    try {
      await _voice.init();
      if (!mounted) return;
      setState(() => _phase = _SparkPhase.speaking);
      await _voice.speak(_openingLine);
    } catch (_) {
      /* TTS can fail on some simulators — bubbles still show the greeting */
    } finally {
      if (mounted) setState(() => _phase = _SparkPhase.idle);
    }
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

  void _resetChatService() {
    _chat = null;
    if (!hasGeminiApiKey) return;
    try {
      _chat = SparkChatService.create(openingMessage: _openingLine);
    } catch (_) {
      _chat = null;
    }
  }

  @override
  void dispose() {
    _avatarBreath.dispose();
    _scroll.dispose();
    _speech.stop();
    unawaited(_voice.stop());
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _onMicPressed() async {
    if (!hasGeminiApiKey) {
      _showKeyHelp();
      return;
    }
    if (_phase == _SparkPhase.thinking) return;

    if (_phase == _SparkPhase.speaking) {
      await _voice.stop();
      if (mounted) setState(() => _phase = _SparkPhase.idle);
      return;
    }

    if (_phase == _SparkPhase.listening) {
      await _stopListeningManually();
      return;
    }

    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not ready yet — try again in a sec!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final mic = await PermissionService.requestMicrophone();
    if (!mic && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Microphone is needed to talk to Buddy. Tap Open Settings to turn it on.',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: () async {
              await openAppSettings();
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _phase = _SparkPhase.listening;
      _liveTranscript = '';
      _sessionLastNonEmpty = '';
      _listenSession = true;
    });
    _finalWordsCompleter = null;

    await _voice.stop();

    _listenStartedAt = DateTime.now();
    try {
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
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 12),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } on ListenFailedException catch (e) {
      _listenStartedAt = null;
      if (mounted) {
        setState(() {
          _phase = _SparkPhase.idle;
          _listenSession = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start listening: ${e.message ?? "try again"}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    } catch (e) {
      _listenStartedAt = null;
      if (mounted) {
        setState(() {
          _phase = _SparkPhase.idle;
          _listenSession = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start listening: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
  }

  Future<void> _stopListeningManually() async {
    _manualStopInProgress = true;
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
    if (!mounted) return;

    final started = _listenStartedAt;
    _listenStartedAt = null;

    final said = (preferredText != null && preferredText.isNotEmpty)
        ? preferredText
        : _rollupTranscript();
    setState(() {
      _phase = _SparkPhase.idle;
      _liveTranscript = '';
      _sessionLastNonEmpty = '';
    });

    if (said.isEmpty) {
      final quickEmpty = started != null &&
          DateTime.now().difference(started) < const Duration(milliseconds: 1600);
      if (mounted && !quickEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("I didn't catch that — tap the mic and try again! 🎤"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await _sendUserLine(said);
  }

  String _rollupTranscript() {
    final live = _liveTranscript.trim();
    if (live.isNotEmpty) return live;
    final last = _speech.lastRecognizedWords.trim();
    if (last.isNotEmpty) return last;
    return _sessionLastNonEmpty;
  }

  Future<void> _sendUserLine(String said) async {
    if (_chat == null) {
      _showKeyHelp();
      return;
    }

    _submitting = true;
    setState(() {
      _bubbles.add(_Bubble(isUser: true, text: said));
      _phase = _SparkPhase.thinking;
    });
    _scrollToBottom();

    try {
      final reply = await _chat!.sendChildMessage(said);
      if (!mounted) return;
      final sparkText = reply ?? 'You’re awesome — tell me more! ⭐';
      setState(() {
        _bubbles.add(_Bubble(isUser: false, text: sparkText));
        _phase = _SparkPhase.speaking;
      });
      _scrollToBottom();

      await _voice.init();
      await _voice.speak(sparkText);
    } on SparkChatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _submitting = false;
      if (mounted) setState(() => _phase = _SparkPhase.idle);
    }
  }

  void _showKeyHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ask a grown-up to add your Gemini key: flutter run --dart-define=GEMINI_API_KEY=…',
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 6),
      ),
    );
  }

  void _newChat() {
    unawaited(_voice.stop());
    unawaited(_speech.stop());
    _openingLine = SparkAiPrompt.randomOpening();
    setState(() {
      _bubbles
        ..clear()
        ..add(_Bubble(isUser: false, text: _openingLine));
      _phase = _SparkPhase.idle;
      _liveTranscript = '';
      _sessionLastNonEmpty = '';
      _listenSession = false;
      _manualStopInProgress = false;
      _finalWordsCompleter = null;
      _submitting = false;
      _listenStartedAt = null;
    });
    _resetChatService();
    _scrollToBottom();
    if (hasGeminiApiKey) {
      unawaited(_speakOpeningIfPossible());
    }
  }

  String get _statusLine {
    switch (_phase) {
      case _SparkPhase.idle:
        return hasGeminiApiKey
            ? 'Tap the big mic to talk to Buddy! 🎤'
            : 'Add a Gemini key to chat with Buddy (see snackbar).';
      case _SparkPhase.listening:
        return 'Listening… tap again when you’re done ✨';
      case _SparkPhase.thinking:
        return 'Buddy is thinking… 🤔';
      case _SparkPhase.speaking:
        return 'Buddy is talking… tap mic to stop';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget avatarSection() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.06).animate(
                CurvedAnimation(parent: _avatarBreath, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.yellow.withValues(alpha: 0.85),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🦊', style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Buddy',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              if (!hasGeminiApiKey)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Buddy needs a Gemini API key. Run the app with '
                          '--dart-define=GEMINI_API_KEY=your_key (ask a grown-up for help).',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(child: avatarSection()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final b = _bubbles[i];
                      return _ChatBubble(isUser: b.isUser, text: b.text);
                    },
                    childCount: _bubbles.length,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 4 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_phase == _SparkPhase.listening && _liveTranscript.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
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
              Text(
                _statusLine,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: RecordControl(
                  onPressed: (_phase == _SparkPhase.thinking && !_listenSession)
                      ? null
                      : _onMicPressed,
                  size: 100,
                  isRecording: _phase == _SparkPhase.listening,
                ),
              ),
              TextButton.icon(
                onPressed: _newChat,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('New chat'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.isUser, required this.text});

  final bool isUser;
  final String text;

  @override
  Widget build(BuildContext context) {
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? AppColors.blue : AppColors.surface;
    final textColor = isUser ? AppColors.white : AppColors.textPrimary;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textColor,
                height: 1.35,
              ),
        ),
      ),
    );
  }
}
