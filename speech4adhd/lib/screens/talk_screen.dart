import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

import '../constants/colors.dart';
import '../constants/prompts.dart';
import '../services/permission_service.dart';
import '../widgets/record_control.dart';

/// Talk practice: random prompt (TTS reads it), record → listen back → positive feedback.
class TalkScreen extends StatefulWidget {
  const TalkScreen({super.key});

  @override
  State<TalkScreen> createState() => _TalkScreenState();
}

class _TalkScreenState extends State<TalkScreen> {
  late String _currentPrompt;
  bool _isRecording = false;
  bool _hasPlayedBack = false;
  bool _showFeedback = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  String? _recordingPath;
  final _random = Random();

  final AudioRecorder _record = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _pickNewPrompt();
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _record.dispose();
    _player.dispose();
    super.dispose();
  }

  void _pickNewPrompt() {
    unawaited(_player.stop());
    setState(() {
      _currentPrompt = talkingPrompts[_random.nextInt(talkingPrompts.length)];
      _hasPlayedBack = false;
      _showFeedback = false;
      _recordedFilePath = null;
      _recordingPath = null;
    });
    _speakPrompt();
  }

  /// TTS reads the prompt — placeholder for flutter_tts.
  Future<void> _speakPrompt() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: FlutterTts().speak(_currentPrompt);
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
            _hasPlayedBack = false;
            _showFeedback = true;
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
          '${dir.path}/speech4adhd_talk_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = path;

      await _record.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
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
      await _player.stop();
      return;
    }

    try {
      await _player.setFilePath(path);
      await _player.play();
      if (mounted) {
        setState(() => _hasPlayedBack = true);
      }
      // _isPlaying follows playerStateStream until complete or stop()
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Oops! Couldn't play — try recording again! 🎤"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Let's Talk!"),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
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
                        Icon(Icons.thumb_up, size: 56, color: AppColors.accent),
                        const SizedBox(height: 8),
                        Text(
                          "You did great!",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                          onPressed: _onPlayBackPressed,
                          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                          label: Text(_isPlaying ? 'Stop' : 'Listen again'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
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
        ),
      ),
    );
  }
}
