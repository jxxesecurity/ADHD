import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

/// Root widget with GoRouter. Material 3 theme in theme.dart.
class Speech4AdhdApp extends StatelessWidget {
  const Speech4AdhdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Speech4ADHD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
