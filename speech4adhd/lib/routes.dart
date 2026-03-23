import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/talk_screen.dart';
import 'screens/debate_screen.dart';
import 'screens/rewards_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// GoRouter configuration: Home, Let's Talk, Quick Debate, My Rewards.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _MainScaffold(
        currentIndex: _calculateSelectedIndex(state.uri.path),
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/talk',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TalkScreen(),
          ),
        ),
        GoRoute(
          path: '/debate',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DebateScreen(),
          ),
        ),
        GoRoute(
          path: '/rewards',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RewardsScreen(),
          ),
        ),
      ],
    ),
  ],
);

int _calculateSelectedIndex(String path) {
  switch (path) {
    case '/talk':
      return 1;
    case '/debate':
      return 2;
    case '/rewards':
      return 3;
    case '/':
    default:
      return 0;
  }
}

class _MainScaffold extends StatelessWidget {
  const _MainScaffold({
    required this.child,
    required this.currentIndex,
  });

  final Widget child;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        // Only the selected tab shows its label — avoids horizontal overflow on small iPhones.
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/talk');
              break;
            case 2:
              context.go('/debate');
              break;
            case 3:
              context.go('/rewards');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic),
            label: 'Talk',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Debate',
            tooltip: 'Quick Debate',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Stars',
            tooltip: 'My Rewards',
          ),
        ],
      ),
    );
  }
}
