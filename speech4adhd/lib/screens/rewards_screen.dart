import 'package:flutter/material.dart';

import '../constants/colors.dart';

/// Stars, badges, confetti on new badge. Placeholder; shared_preferences next.
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const int _placeholderStars = 0;
  static const int _placeholderLevel = 1;
  static const int _placeholderStreak = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Rewards'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.star,
                size: 80,
                color: AppColors.yellow,
              ),
              const SizedBox(height: 16),
              Text(
                'Total Stars: $_placeholderStars',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Level $_placeholderLevel',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.accent,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Day streak: $_placeholderStreak 🔥',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'Badges',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _BadgePlaceholder(
                        icon: Icons.mic,
                        label: 'First Talk',
                        earned: false,
                      ),
                      _BadgePlaceholder(
                        icon: Icons.star,
                        label: '5 Stars',
                        earned: false,
                      ),
                      _BadgePlaceholder(
                        icon: Icons.forum,
                        label: 'First Debate',
                        earned: false,
                      ),
                      _BadgePlaceholder(
                        icon: Icons.local_fire_department,
                        label: '3-Day Streak',
                        earned: false,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Keep practicing to earn more stars and badges!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgePlaceholder extends StatelessWidget {
  const _BadgePlaceholder({
    required this.icon,
    required this.label,
    required this.earned,
  });

  final IconData icon;
  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 48,
          color: earned
              ? AppColors.accent
              : AppColors.textSecondary.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: earned ? AppColors.textPrimary : AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
