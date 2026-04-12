import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'env_reader_stub.dart'
    if (dart.library.io) 'env_reader_io.dart' as env_reader;

/// Resolves the Gemini API key without committing secrets to the repo.
///
/// **Order:** `--dart-define` → bundled `assets/default.env` (via [dotenv]) →
/// process environment (desktop).
///
/// **Recommended for CI / release:** pass at build/run time:
/// ```bash
/// flutter run --dart-define=GEMINI_API_KEY=your_key_here
/// ```
String resolveGeminiApiKey() {
  const fromDefine = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (fromDefine.isNotEmpty) return fromDefine;

  final fromDotenv = dotenv.env['GEMINI_API_KEY']?.trim();
  if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;

  final fromShell = env_reader.readProcessEnv('GEMINI_API_KEY');
  if (fromShell != null && fromShell.isNotEmpty) return fromShell;

  return '';
}

bool get hasGeminiApiKey => resolveGeminiApiKey().isNotEmpty;
