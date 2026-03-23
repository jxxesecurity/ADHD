import 'env_reader_stub.dart'
    if (dart.library.io) 'env_reader_io.dart' as env_reader;

/// Resolves the Gemini API key without committing secrets to the repo.
///
/// **Recommended (all platforms):** pass at build/run time:
/// ```bash
/// flutter run --dart-define=GEMINI_API_KEY=your_key_here
/// ```
///
/// **Desktop:** you can export `GEMINI_API_KEY` in your shell before `flutter run`.
String resolveGeminiApiKey() {
  const fromDefine = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  if (fromDefine.isNotEmpty) return fromDefine;

  final fromShell = env_reader.readProcessEnv('GEMINI_API_KEY');
  if (fromShell != null && fromShell.isNotEmpty) return fromShell;

  return '';
}

bool get hasGeminiApiKey => resolveGeminiApiKey().isNotEmpty;
