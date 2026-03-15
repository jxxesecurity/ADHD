import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/prompts.dart';
import '../services/permission_service.dart';
import '../widgets/record_control.dart';

/// Talk practice: random prompt (TTS reads it), record → listen back → positive feedback.
/// Placeholder for real recording/TTS; mic permission on first use.
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
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _pickNewPrompt();
  }

  void _pickNewPrompt() {
    setState(() {
      _currentPrompt = talkingPrompts[_random.nextInt(talkingPrompts.length)];
      _hasPlayedBack = false;
      _showFeedback = false;
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
      // TODO: stop recording, then play back
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        _hasPlayedBack = true;
        _showFeedback = true;
      });
      return;
    }
    final granted = await PermissionService.requestMicrophone();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is needed to record. Enable it in Settings.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isRecording = true);
    // TODO: start flutter_sound recording
  }

  void _onPlayBackPressed() {
    // TODO: play recorded file with flutter_sound
    setState(() {
      _hasPlayedBack = true;
      _showFeedback = true;
    });
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
                _isRecording ? 'Recording...' : 'Tap to record',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (_hasPlayedBack && !_isRecording) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _onPlayBackPressed,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Listen again'),
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
