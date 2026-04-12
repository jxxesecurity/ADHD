# Gemini API key (Spark chat)

**Chat with Spark** uses [Google AI Studio](https://aistudio.google.com/) (Gemini). You need an API key on your **machine** or in your **CI** — never commit keys to git.

## Option A — bundled `assets/default.env` (dev)

The app loads `assets/default.env` at startup (see `lib/main.dart`). You can put your key there:

```
GEMINI_API_KEY=paste_your_key_here
```

For **public repos**, prefer `--dart-define` or a backend so you don’t commit keys.

### Model not found / `generateContent` errors

Google retires model names over time. The app uses **`gemini-2.5-flash`** by default (`lib/services/spark_chat_service.dart`). If you see errors like *“model is not found for API version v1beta”*, check [current model IDs](https://ai.google.dev/gemini-api/docs/models/gemini) and update `defaultModel` in code to a listed Flash model (e.g. `gemini-2.5-flash-lite`).

## Option B — `--dart-define` (recommended for releases)

Run or build with:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

**Xcode (physical iPhone):**

1. **Product → Scheme → Edit Scheme…**
2. **Run → Arguments → Arguments Passed On Launch** is wrong for defines; use **Build Settings** or add to **Run** under **Environment Variables** only for desktop.

For iOS from CLI, pass defines to Flutter:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY_HERE
```

For **Archive / Release**, add the same `--dart-define` in your CI or a small build script. Avoid hardcoding the key inside `Info.plist` or Dart source files that you commit.

## Option C — shell environment (desktop)

```bash
export GEMINI_API_KEY=YOUR_KEY_HERE
flutter run
```

(`lib/config/gemini_config.dart` reads `Platform.environment` on IO platforms.)

## Security tips

- Rotate keys if they leak.
- Prefer **separate keys** per developer or per build flavor.
- For production, use your backend to call Gemini (key stays on server) — this sample calls Gemini **from the app** for simplicity (key can be extracted from a shipped app), which is OK for prototypes and family devices with care.

## Parent / COPPA note

Spark is designed for light, kid-friendly topics. Review Google’s terms and your obligations for children’s data before shipping widely.
