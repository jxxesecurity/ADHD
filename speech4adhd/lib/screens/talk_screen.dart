import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_sound/flutter_sound.dart';

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
  final _random = Random();

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  static const Codec _codec = Codec.aacMP4;

  @override
  void initState() {
    super.initState();
    _pickNewPrompt();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  void _pickNewPrompt() {
    setState(() {
      _currentPrompt = talkingPrompts[_random.nextInt(talkingPrompts.length)];
      _hasPlayedBack = false;
      _showFeedback = false;
      _recordedFilePath = null;
    });
    _speakPrompt();
  }

  /// TTS reads the prompt — placeholder for flutter_tts.
  Future<void> _speakPrompt() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: FlutterTts().speak(_currentPrompt);
  }

  Future<void> _onRecordPressed() async {
    if (_isRecording) {
      setState(() => _isRecording = false);
      try {
        final path = await _recorder.stopRecorder();
        if (mounted && path != null && path.isNotEmpty) {
          // Keep the raw path returned by flutter_sound; use it directly for playback.
          setState(() {
            _recordedFilePath = path;
            _hasPlayedBack = false;
            _showFeedback = true;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not stop recording: $e')),
          );
        }
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

    try {
      // Let flutter_sound manage the storage location; we just give it a file name.
      const fileName = 'speech4adhd_talk.mp4';
      await _recorder.startRecorder(
        toFile: fileName,
        codec: _codec,
        sampleRate: 44100,
        numChannels: 1,
      );
      if (mounted) setState(() => _isRecording = true);
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

    // Some platforms may return a file URI like file://...; normalize to a real path for File().
    final normalizedPath = path.startsWith('file://') ? path.substring(7) : path;
    final file = File(normalizedPath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording file not found. Record again.')),
        );
      }
      return;
    }

    if (_isPlaying) {
      await _player.stopPlayer();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    try {
      setState(() => _isPlaying = true);
      await _player.startPlayer(
        fromURI: normalizedPath,
        codec: _codec,
        whenFinished: () {
          if (mounted) setState(() => _isPlaying = false);
        },
      );
      if (mounted) setState(() => _hasPlayedBack = true);
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play back: $e')),
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
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
                const SizedBox(height: 24),
                Icon(Icons.thumb_up, size: 56, color: AppColors.accent),
                const SizedBox(height: 8),
                Text(
                  "You did great!",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                ),
              ],
              const Spacer(),
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
                const SizedBox(height: 16),
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
              const Spacer(),
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
  }
}
