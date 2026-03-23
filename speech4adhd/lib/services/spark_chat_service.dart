import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_config.dart';
import '../constants/spark_ai_prompt.dart';

/// Gemini-backed chat session for Spark, with short history for context.
class SparkChatService {
  SparkChatService._(this._chat);

  final ChatSession _chat;

  /// Model id — flash is fast and works well for short kid-friendly replies.
  static const String defaultModel = 'gemini-1.5-flash';

  /// Create a new chat with Spark's opening line already in history.
  factory SparkChatService.create({String? apiKey, String model = defaultModel}) {
    final key = apiKey ?? resolveGeminiApiKey();
    if (key.isEmpty) {
      throw StateError('Missing GEMINI_API_KEY. Add --dart-define=GEMINI_API_KEY=... when running.');
    }

    final modelInstance = GenerativeModel(
      model: model,
      apiKey: key,
      systemInstruction: Content.system(SparkAiPrompt.system),
      generationConfig: GenerationConfig(
        maxOutputTokens: 256,
        temperature: 0.9,
      ),
    );

    final chat = modelInstance.startChat(
      history: [
        Content.model([TextPart(SparkAiPrompt.openingGreeting)]),
      ],
    );

    return SparkChatService._(chat);
  }

  /// Send the child's message; returns Spark's reply text or null if blocked/empty.
  Future<String?> sendChildMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;

    try {
      final response = await _chat.sendMessage(Content.text(trimmed));
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return "Hmm, I got a little mixed up — tell me that again? 😊";
      }
      return text;
    } on GenerativeAIException catch (e) {
      throw SparkChatException('Spark had a problem: ${e.message}');
    } catch (e) {
      throw SparkChatException('Could not reach Spark. Check the internet and try again! ($e)');
    }
  }
}

class SparkChatException implements Exception {
  SparkChatException(this.message);
  final String message;

  @override
  String toString() => message;
}
