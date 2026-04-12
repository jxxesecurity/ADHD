import 'package:flutter/material.dart';

import '../widgets/talk_free_mode.dart';

/// Prompt + record + replay — opened from Home as **My Voice**.
class MyVoiceScreen extends StatelessWidget {
  const MyVoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Voice'),
        ),
        body: const TalkFreeMode(),
      ),
    );
  }
}
