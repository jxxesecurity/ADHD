import 'package:flutter/material.dart';

import 'app.dart';

// TODO: Add splash screen and app icon.
// - Place app icon in: android/app/src/main/res/mipmap-* and ios/Runner/Assets.xcassets/AppIcon.appiconset
// - Add flutter_native_splash or configure launch screens for splash

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Speech4AdhdApp());
}
