import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/colors.dart';
import '../constants/prompts.dart';
import '../services/permission_service.dart';
import '../widgets/big_friendly_button.dart';
import '../widgets/record_control.dart';

/// Quick debate: pick agree/disagree, speak why, short timer (1–3 min).
class DebateScreen extends StatefulWidget {
  const DebateScreen({super.key});

  @override
  State<DebateScreen> createState() => _DebateScreenState();
}

class _DebateScreenState extends State<DebateScreen> {
  late String _topic;
  bool? _side; // true = agree, false = disagree
  bool _isRecording = false;
  bool _showFeedback = false;
  int _secondsLeft = 0;
  static const int _timerSeconds = 90; // 1.5 min
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _pickNewTopic();
  }

  void _pickNewTopic() {
    setState(() {
      _topic = debateTopics[_random.nextInt(debateTopics.length)];
      _side = null;
      _isRecording = false;
      _showFeedback = false;
      _secondsLeft = 0;
    });
  }

  void _chooseSide(bool agree) {
    setState(() {
      _side = agree;
      _secondsLeft = _timerSeconds;
    });
  }

  Future<void> _onRecordPressed() async {
    if (_isRecording) {
      setState(() => _isRecording = false);
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _showFeedback = true);
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
    setState(() => _isRecording = true);
    // TODO: start recording; optional countdown timer
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quick Debate'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Topic:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _topic,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_side == null) ...[
                Text(
                  'Pick a side!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: BigFriendlyButton(
                        label: 'Agree',
                        icon: Icons.thumb_up,
                        backgroundColor: AppColors.accent,
                        onPressed: () => _chooseSide(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BigFriendlyButton(
                        label: 'Disagree',
                        icon: Icons.thumb_down,
                        backgroundColor: AppColors.blue,
                        onPressed: () => _chooseSide(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: _pickNewTopic,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New topic'),
                ),
              ] else ...[
                Text(
                  _side! ? "Why do you agree?" : "Why do you disagree?",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_timerSeconds > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'About ${_timerSeconds ~/ 60} min — say your reason!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                const Spacer(),
                RecordControl(
                  onPressed: _onRecordPressed,
                  size: 100,
                  isRecording: _isRecording,
                ),
                const SizedBox(height: 16),
                Text(
                  _isRecording ? 'Recording...' : 'Tap to record your reason',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (_showFeedback) ...[
                  const SizedBox(height: 24),
                  Text(
                    "Nice job! Great opinion!",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.accent,
                        ),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickNewTopic,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New topic'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
