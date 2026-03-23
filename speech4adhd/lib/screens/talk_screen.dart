import 'package:flutter/material.dart';

import '../widgets/talk_free_mode.dart';
import '../widgets/talk_spark_panel.dart';

/// Let's Talk: default **Chat with Spark** (AI + STT + TTS), optional **Free Talk** monologue.
class TalkScreen extends StatefulWidget {
  const TalkScreen({super.key});

  @override
  State<TalkScreen> createState() => _TalkScreenState();
}

enum _TalkMode { spark, free }

class _TalkScreenState extends State<TalkScreen> {
  _TalkMode _mode = _TalkMode.spark;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Let's Talk!"),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SegmentedButton<_TalkMode>(
                segments: const [
                  ButtonSegment<_TalkMode>(
                    value: _TalkMode.spark,
                    label: Text('Chat with Spark'),
                    icon: Icon(Icons.forum_rounded),
                    tooltip: 'Talk with AI buddy Spark',
                  ),
                  ButtonSegment<_TalkMode>(
                    value: _TalkMode.free,
                    label: Text('Free Talk'),
                    icon: Icon(Icons.record_voice_over_rounded),
                    tooltip: 'Prompt + record + listen back',
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) {
                  setState(() => _mode = s.first);
                },
              ),
            ),
            Expanded(
              child: _mode == _TalkMode.spark
                  ? const TalkSparkPanel()
                  : const TalkFreeMode(),
            ),
          ],
        ),
      ),
    );
  }
}
