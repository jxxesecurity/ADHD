import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../config/gemini_config.dart';
import '../constants/colors.dart';
import '../constants/prompts.dart';
import '../services/buddy_says_service.dart';
import '../services/permission_service.dart';
import '../services/spark_voice_service.dart';
import 'record_control.dart';

/// Original monologue flow: random prompt, record, listen back — low-pressure practice.
class TalkFreeMode extends StatefulWidget {
  const TalkFreeMode({super.key});

  @override
  State<TalkFreeMode> createState() => _TalkFreeModeState();
}

class _TalkFreeModeState extends State<TalkFreeMode> {
  late String _currentPrompt;
  bool _isRecording = false;
  bool _showFeedback = false;
  bool _isPlaying = false;
  bool _buddyBusy = false;
  String? _buddyRepeatText;
  String? _recordedFilePath;
  String? _recordingPath;
  final _random = Random();

  final AudioRecorder _record = AudioRecorder();
  final SparkVoiceService _voice = SparkVoiceService();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<ProcessingState>? _processingStateSub;
  StreamSubscription<Duration>? _playbackPositionSub;

  @override
  void initState() {
    super.initState();
    _pickNewPrompt();
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      // Treat "completed" as not playing even if a stale `playing: true` slips through (iOS quirk).
      final logicalPlaying = state.playing &&
          state.processingState != ProcessingState.completed;
      setState(() => _isPlaying = logicalPlaying);
    });
    _processingStateSub = _player.processingStateStream.listen((ps) {
      if (!mounted) return;
      // Reliable end signal on some devices; also clears UI if replay gets stuck after first play.
      if (ps == ProcessingState.completed) {
        setState(() => _isPlaying = false);
        _cancelPlaybackEndFallback();
      }
    });
  }

  void _cancelPlaybackEndFallback() {
    _playbackPositionSub?.cancel();
    _playbackPositionSub = null;
  }

  /// Some simulators/devices never emit `completed` / `playing: false` — detect end via position.
  void _startPlaybackEndFallback() {
    _cancelPlaybackEndFallback();
    _playbackPositionSub = _player.positionStream.listen((pos) {
      final dur = _player.duration;
      if (dur == null || dur == Duration.zero) return;
      if (pos.inMilliseconds >= dur.inMilliseconds - 250) {
        if (!mounted) return;
        setState(() => _isPlaying = false);
        _cancelPlaybackEndFallback();
      }
    });
  }

  @override
  void dispose() {
    _cancelPlaybackEndFallback();
    _playerStateSub?.cancel();
    _processingStateSub?.cancel();
    _record.dispose();
    _player.dispose();
    unawaited(_voice.stop());
    super.dispose();
  }

  void _pickNewPrompt() {
    _cancelPlaybackEndFallback();
    unawaited(_player.stop());
    unawaited(_voice.stop());
    setState(() {
      _currentPrompt = talkingPrompts[_random.nextInt(talkingPrompts.length)];
      _showFeedback = false;
      _recordedFilePath = null;
      _recordingPath = null;
      _buddyRepeatText = null;
    });
  }

  Future<void> _onRecordPressed() async {
    try {
      if (_isRecording) {
        setState(() => _isRecording = false);
        final stopped = await _record.stop();
        final path =
            (stopped != null && stopped.isNotEmpty) ? stopped : _recordingPath;
        _recordingPath = null;
        if (mounted && path != null && path.isNotEmpty) {
          setState(() {
            _recordedFilePath = path;
            _showFeedback = true;
            _buddyRepeatText = null;
          });
        }
        return;
      }

      final granted = await PermissionService.requestMicrophone();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Microphone is off. Tap "Open Settings" and turn on Microphone for this app.',
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

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/mymic_talk_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = path;

      await _record.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
          // Advanced codec path is flaky on some Android emulators; MediaRecorder is more stable.
          androidConfig: const AndroidRecordConfig(
            useLegacy: true,
            audioSource: AndroidAudioSource.mic,
          ),
        ),
        path: path,
      );
      if (mounted) {
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _onPlayBackPressed() async {
    final path = _recordedFilePath;
    if (path == null || path.isEmpty) return;

    final file = File(path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording file not found. Record again.')),
        );
      }
      return;
    }

    if (_isPlaying) {
      _cancelPlaybackEndFallback();
      await _player.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    try {
      _cancelPlaybackEndFallback();
      // Clear completed/stale state so replay emits position + processing events reliably.
      await _player.stop();
      await _player.setFilePath(path);
      await _player.seek(Duration.zero);
      await _player.play();
      if (mounted) {
        setState(() => _isPlaying = true);
        _startPlaybackEndFallback();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Oops! Couldn't play — try recording again! 🎤"),
          ),
        );
      }
    }
  }

  void _showGeminiKeyHelp() {
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

  Future<void> _onBuddySaysPressed() async {
    if (_buddyBusy) return;
    final path = _recordedFilePath;
    if (path == null || path.isEmpty) return;

    if (!hasGeminiApiKey) {
      _showGeminiKeyHelp();
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording file not found. Record again.')),
        );
      }
      return;
    }

    setState(() => _buddyBusy = true);
    try {
      if (_isPlaying) {
        _cancelPlaybackEndFallback();
        await _player.stop();
        if (mounted) setState(() => _isPlaying = false);
      }
      await _voice.stop();

      final repeat = await BuddySaysService.repeatFromM4aRecording(path);
      if (!mounted) return;
      setState(() => _buddyRepeatText = repeat);
      await _voice.speak(repeat);
    } on BuddySaysException catch (e) {
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
      if (mounted) setState(() => _buddyBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Your prompt:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _currentPrompt,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (_showFeedback) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Icon(
                        Icons.thumb_up,
                        size: 56,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  RecordControl(
                    onPressed: _onRecordPressed,
                    size: 120,
                    isRecording: _isRecording,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording
                        ? 'Recording...'
                        : _isPlaying
                            ? 'Playing...'
                            : 'Tap to record',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (_recordedFilePath != null && !_isRecording) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _buddyBusy ? null : _onPlayBackPressed,
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Stop' : 'Listen again'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _buddyBusy ? null : _onBuddySaysPressed,
                      icon: _buddyBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_buddyBusy ? 'Buddy is thinking…' : 'Buddy repeats'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    if (_buddyRepeatText != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: AppColors.blue.withValues(alpha: 0.12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buddy repeats:',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppColors.primary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _buddyRepeatText!,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _pickNewPrompt,
                    icon: const Icon(Icons.refresh),
                    label: const Text('New prompt'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
