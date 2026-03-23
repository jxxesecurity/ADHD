# Speech4ADHD

Flutter app for kids **~6–12** with ADHD: short verbal activities, **Chat with Spark** (AI buddy), optional **Free Talk** (prompt + record + replay), quick debate, rewards.

## Chat with Spark (Gemini)

Spark uses **speech-to-text** → **Google Gemini** → **text-to-speech**. You must provide a Gemini API key at run time.

See **[docs/GEMINI_SETUP.md](docs/GEMINI_SETUP.md)** for `--dart-define=GEMINI_API_KEY=...` and safety notes.

```bash
flutter pub get
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

## Features

- **Let's Talk** — segmented control: **Chat with Spark** | **Free Talk**
- **Quick Debate**, **Rewards**, etc.

## Requirements

- Flutter SDK (see `pubspec.yaml` for Dart SDK)
- Microphone + (for Spark) speech recognition permission on iOS/Android
- Internet for Gemini (Spark only)

## Getting started

- [Flutter install](https://docs.flutter.dev/get-started/install)
- iOS: open `ios/Runner.xcworkspace`, set signing team for a physical device if needed.
