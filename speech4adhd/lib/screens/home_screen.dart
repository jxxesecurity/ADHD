import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/colors.dart';
import '../widgets/big_friendly_button.dart';
import '../widgets/animated_mascot.dart';

/// Welcome screen: big welcome, mascot, TTS greeting, and main action buttons.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _speakGreeting();
  }

  /// TTS: "Hi friend! Ready to talk?" — placeholder; integrate flutter_tts next.
  Future<void> _speakGreeting() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // TODO: FlutterTts().speak('Hi friend! Ready to talk?');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              const AnimatedMascot(size: 120),
              const SizedBox(height: 24),
              Text(
                'Speech4ADHD',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.primary,
                      fontSize: 34,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Hi friend! Ready to talk?",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 1),
              BigFriendlyButton(
                label: "Let's Talk!",
                icon: Icons.mic,
                backgroundColor: AppColors.primary,
                onPressed: () => context.go('/talk'),
              ),
              const SizedBox(height: 16),
              BigFriendlyButton(
                label: 'Quick Debate',
                icon: Icons.forum,
                backgroundColor: AppColors.accent,
                onPressed: () => context.go('/debate'),
              ),
              const SizedBox(height: 16),
              BigFriendlyButton(
                label: 'My Rewards',
                icon: Icons.star,
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.textPrimary,
                onPressed: () => context.go('/rewards'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
