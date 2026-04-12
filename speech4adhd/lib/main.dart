import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';

// TODO: Add splash screen and app icon.
// - Place app icon in: android/app/src/main/res/mipmap-* and ios/Runner/Assets.xcassets/AppIcon.appiconset
// - Add flutter_native_splash or configure launch screens for splash

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads bundled env (see assets/default.env). Safe if the file is missing.
  // Prefer `--dart-define=GEMINI_API_KEY=...` for CI / release (see docs/GEMINI_SETUP.md).
  await dotenv.load(fileName: 'assets/default.env', isOptional: true);

  runApp(const MyMicApp());
}
