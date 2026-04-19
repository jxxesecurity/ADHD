import 'dart:io';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_config.dart';
import 'spark_chat_service.dart';

/// Sends a short recording to Gemini and returns text for Buddy to speak back (faithful repeat).
class BuddySaysService {
  BuddySaysService._();

  static const String _userPrompt = '''
The attached audio is a child (ages 6–14) answering a speaking prompt out loud.

Your job is to REPEAT what they said — not to rewrite, improve, or summarize.

1. Transcribe their words as faithfully as you can (same order and meaning). Keep their phrasing, fillers like "um" only if needed for clarity; otherwise omit fillers.
2. If a word is truly unclear, guess the closest match to what they likely said — do not invent a new idea.
3. Output ONLY the words Buddy should speak back, as one flowing line. No title, no "You said", no quotes around the whole thing, no explanation.
''';

  static String _cleanOutput(String raw) {
    var s = raw.trim();
    if (s.length >= 2 && s.startsWith('"') && s.endsWith('"')) {
      s = s.substring(1, s.length - 1).trim();
    }
    if (s.length >= 2 && s.startsWith('“') && s.endsWith('”')) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s;
  }

  /// Reads [m4aPath] (AAC in .m4a) and returns text that repeats what the child said.
  static Future<String> repeatFromM4aRecording(String m4aPath) async {
    final key = resolveGeminiApiKey();
    if (key.isEmpty) {
      throw BuddySaysException(
        'Add a Gemini key: flutter run --dart-define=GEMINI_API_KEY=…',
      );
    }

    final file = File(m4aPath);
    if (!await file.exists()) {
      throw BuddySaysException('Recording file not found.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw BuddySaysException('Recording is empty.');
    }

    final model = GenerativeModel(
      model: SparkChatService.defaultModel,
      apiKey: key,
      systemInstruction: Content.system(
        'You repeat what a child said so they can hear it back in clear speech. '
        'Do not rephrase for style or grammar — stay faithful to their words. '
        'Output only the line to speak — nothing else.',
      ),
      generationConfig: GenerationConfig(
        maxOutputTokens: 256,
        temperature: 0.2,
      ),
    );

    try {
      final response = await model.generateContent([
        Content.multi([
          TextPart(_userPrompt),
          DataPart('audio/mp4', Uint8List.fromList(bytes)),
        ]),
      ]);

      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw BuddySaysException(
          'Buddy could not understand the recording — try speaking a bit louder.',
        );
      }
      return _cleanOutput(text);
    } on GenerativeAIException catch (e) {
      throw BuddySaysException('Buddy had a problem: ${e.message}');
    } catch (e) {
      throw BuddySaysException(
        'Could not reach Buddy. Check the internet and try again. ($e)',
      );
    }
  }
}

class BuddySaysException implements Exception {
  BuddySaysException(this.message);
  final String message;

  @override
  String toString() => message;
}
