import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

/// Root widget with GoRouter. Material 3 theme in theme.dart.
class MyMicApp extends StatelessWidget {
  const MyMicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'myMic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
