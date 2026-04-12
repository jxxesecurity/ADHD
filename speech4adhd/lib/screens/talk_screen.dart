import 'package:flutter/material.dart';

import '../widgets/talk_spark_panel.dart';

/// Chat with Buddy (AI + STT + TTS).
class TalkScreen extends StatelessWidget {
  const TalkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Let's Chat"),
        ),
        body: const TalkSparkPanel(),
      ),
    );
  }
}
