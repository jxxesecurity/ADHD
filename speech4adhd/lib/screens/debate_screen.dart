import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../constants/prompts.dart';
import '../widgets/big_friendly_button.dart';
import '../widgets/debate_spark_panel.dart';

/// Quick debate: topic → Agree/Disagree → Spark reacts (STT + AI + TTS).
class DebateScreen extends StatefulWidget {
  const DebateScreen({super.key});

  @override
  State<DebateScreen> createState() => _DebateScreenState();
}

class _DebateScreenState extends State<DebateScreen> {
  late String _topic;
  bool? _side; // true = agree, false = disagree
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _topic = pickDebateTopic(_random);
  }

  void _pickNewTopic() {
    final previous = _topic;
    setState(() {
      _topic = pickDebateTopic(_random, avoid: previous);
      _side = null;
    });
  }

  void _chooseSide(bool agree) {
    setState(() => _side = agree);
  }

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
    return TextButton(
      onPressed: _pickNewTopic,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh, size: 22),
          SizedBox(width: 8),
          Text('New topic'),
        ],
      ),
    );
  }

  Widget _debateStickyActions() {
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _newTopicButton(),
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
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                            const SizedBox(height: 12),
                            if (_side == null) ...[
                              Text(
                                'Pick a side!',
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              _agreeDisagreeButtons(),
                            ] else ...[
                              Text(
                                _side! ? "Why do you agree?" : "Why do you disagree?",
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              DebateSparkPanel(
                                key: ValueKey('$_topic' '_' '$_side'),
                                topic: _topic,
                                agreed: _side!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _debateStickyActions(),
          ],
        ),
      ),
    );
  }
}
