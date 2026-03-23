import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../constants/colors.dart';
import '../constants/prompts.dart';
import '../services/permission_service.dart';
import '../widgets/big_friendly_button.dart';
import '../widgets/record_control.dart';

/// Quick debate: pick agree/disagree, speak why, record → listen back (like Let's Talk).
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
  bool _isPlaying = false;
  String? _recordedFilePath;
  /// Path passed to [AudioRecorder.start]; used if [AudioRecorder.stop] returns null.
  String? _recordingPath;
  static const int _timerSeconds = 90; // 1.5 min
  final _random = Random();

  final AudioRecorder _record = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  // #region agent log
  static const _kHostDebugLog =
      '/Users/yanchou/projects/ADHD/speech4adhd/.cursor/debug-db3ee5.log';

  void _agentLog(String hypothesisId, String message, Map<String, Object?> data) {
    final line = jsonEncode({
      'sessionId': 'db3ee5',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': 'debate_screen.dart',
      'message': message,
      'data': data,
      'hypothesisId': hypothesisId,
      'runId': 'post-fix',
    });
    debugPrint('DEBUG_DB3EE5: $line');
    try {
      if (Platform.isMacOS) {
        File(_kHostDebugLog).writeAsStringSync('$line\n', mode: FileMode.append);
      }
    } catch (_) {}
  }
  // #endregion

  @override
  void initState() {
    super.initState();
    _pickNewTopic();
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      // #region agent log
      _agentLog('H1', 'playerStateStream', {'playing': state.playing});
      // #endregion
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

  void _pickNewTopic() {
    unawaited(_player.stop());
    setState(() {
      _topic = debateTopics[_random.nextInt(debateTopics.length)];
      _side = null;
      _isRecording = false;
      _showFeedback = false;
      _recordedFilePath = null;
      _recordingPath = null;
      _isPlaying = false;
    });
  }

  void _chooseSide(bool agree) {
    unawaited(_player.stop());
    setState(() {
      _side = agree;
      _recordedFilePath = null;
      _recordingPath = null;
      _showFeedback = false;
      _isPlaying = false;
    });
  }

  Future<void> _onRecordPressed() async {
    try {
      if (_isRecording) {
        setState(() => _isRecording = false);
        final stopped = await _record.stop();
        final path = (stopped != null && stopped.isNotEmpty) ? stopped : _recordingPath;
        _recordingPath = null;
        // #region agent log
        _agentLog('H3', 'record_stop', {
          'stoppedNull': stopped == null,
          'stoppedEmpty': stopped?.isEmpty ?? false,
          'usedFallback': stopped == null || stopped.isEmpty,
          'pathOk': path != null && path.isNotEmpty,
        });
        // #endregion
        if (mounted && path != null && path.isNotEmpty) {
          setState(() {
            _recordedFilePath = path;
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
          '${dir.path}/speech4adhd_debate_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = path;

      await _record.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
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
      // #region agent log
      _agentLog('H1', 'playback_stop_requested', {});
      // #endregion
      await _player.stop();
      return;
    }

    try {
      // #region agent log
      _agentLog('H1', 'playback_start', {'pathLen': path.length});
      // #endregion
      await _player.setFilePath(path);
      await _player.play();
      // _isPlaying follows playerStateStream until complete or stop()
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
        // #region agent log
        _agentLog('H2', 'playback_error', {'error': e.toString()});
        // #endregion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Oops! Couldn't play — try recording again! 🎤"),
          ),
        );
      }
    }
  }

  /// Agree / Disagree side by side; each button flexes to half width (minus gap).
  Widget _agreeDisagreeButtons() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BigFriendlyButton(
            label: 'Agree',
            icon: Icons.thumb_up,
            backgroundColor: AppColors.accent,
            onPressed: () => _chooseSide(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BigFriendlyButton(
            label: 'Disagree',
            icon: Icons.thumb_down,
            backgroundColor: AppColors.blue,
            onPressed: () => _chooseSide(false),
          ),
        ),
      ],
    );
  }

  Widget _newTopicButton() {
    return Center(
      child: TextButton(
        onPressed: _pickNewTopic,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 22),
            SizedBox(width: 8),
            Text('New topic'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Debate'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.paddingOf(context).bottom + 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Topic:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _topic,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_side == null) ...[
                      Text(
                        'Pick a side!',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      _agreeDisagreeButtons(),
                      const SizedBox(height: 16),
                      _newTopicButton(),
                    ] else ...[
                      Text(
                        _side! ? "Why do you agree?" : "Why do you disagree?",
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (_timerSeconds > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'About ${_timerSeconds ~/ 60} min — say your reason!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (_showFeedback) ...[
                        const SizedBox(height: 16),
                        Icon(Icons.thumb_up, size: 48, color: AppColors.accent),
                        const SizedBox(height: 8),
                        Text(
                          "Nice job! Great opinion!",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.accent,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Center(
                        child: RecordControl(
                          onPressed: _onRecordPressed,
                          size: 100,
                          isRecording: _isRecording,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isRecording
                            ? 'Recording...'
                            : _isPlaying
                                ? 'Playing...'
                                : 'Tap to record your reason',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
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
                      _newTopicButton(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
