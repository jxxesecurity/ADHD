import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/my_voice_screen.dart';
import 'screens/talk_screen.dart';
import 'screens/debate_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

/// GoRouter configuration: Home, My Voice, Let's Chat, Quick Debate.
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
          path: '/my-voice',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MyVoiceScreen(),
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
      ],
    ),
  ],
);

int _calculateSelectedIndex(String path) {
  switch (path) {
    case '/my-voice':
      return 0;
    case '/talk':
      return 1;
    case '/debate':
      return 2;
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
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Chat',
            tooltip: "Let's Chat",
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Debate',
            tooltip: 'Quick Debate',
          ),
        ],
      ),
    );
  }
}
