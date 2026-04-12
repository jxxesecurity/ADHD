import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_config.dart';
import '../constants/spark_ai_prompt.dart';
import 'spark_chat_service.dart';

/// One-shot Gemini soft rebuttal for Quick Debate (Buddy).
class DebateSparkService {
  DebateSparkService._();

  static const String _offlineMsg =
      "Buddy can't reach the internet right now. Check your connection and try again!";

  static bool _isReplyTooThin(String? text) {
    if (text == null) return true;
    final s = text.trim();
    if (s.length < 120) return true;
    final sentenceEndings = RegExp(r'[.!?]').allMatches(s).length;
    if (sentenceEndings < 2) return true;
    final roughChunks = s.split(RegExp(r'[.!?]+')).where((c) => c.trim().length > 12).length;
    if (roughChunks < 3) return true;
    return false;
  }

  static String _debateUserPrompt({
    required String topic,
    required bool agreed,
    required String whatTheySaid,
    bool repair = false,
    String? badPreviousReply,
  }) {
    if (repair && badPreviousReply != null) {
      return '''
Your last answer was REJECTED because it was too short or only one sentence.

Bad reply (do not imitate): "$badPreviousReply"

Rewrite completely as Buddy. REQUIRED:
- At least FOUR full sentences with periods or question marks between them.
- Name something concrete from the kid’s idea or the topic (not just "smart" or "great point").
- Include one gentle "some people think…" line about THIS topic.
- End with encouragement and one question.

Debate topic: $topic
Kid chose: ${agreed ? 'Agree' : 'Disagree'}
What they said: $whatTheySaid
''';
    }

    return '''
TASK — Buddy’s debate turn (must obey every line):

1) Write AT LEAST FOUR separate sentences. Put a period, ?, or ! after each sentence so they are clearly separate.
2) Sentences 1–2: Praise that mentions their actual idea or words (paraphrase from "What they said" below). Do not use only vague praise like "such a smart point" without saying WHAT was smart.
3) Sentence 3: One gentle other view for this topic ("Some friends say…", "Another way to see it…").
4) Sentence 4: Encouragement + one simple question about the topic.

Debate topic: $topic
The kid chose: ${agreed ? 'Agree' : 'Disagree'}
What they said (speech text, may have errors): $whatTheySaid

Now write Buddy’s reply only — no bullet numbers in the answer, just Buddy’s friendly speech.
''';
  }

  static bool _looksLikeNetworkIssue(String message) {
    final m = message.toLowerCase();
    return m.contains('socket') ||
        m.contains('network') ||
        m.contains('connection') ||
        m.contains('host lookup') ||
        m.contains('failed host') ||
        m.contains('timed out') ||
        m.contains('timeout') ||
        m.contains('internet');
  }

  static Future<String> react({
    required String topic,
    required bool agreed,
    required String whatTheySaid,
  }) async {
    final key = resolveGeminiApiKey();
    if (key.isEmpty) {
      throw DebateSparkException(
        'Add a Gemini API key for Buddy: --dart-define=GEMINI_API_KEY=…',
      );
    }

    final model = GenerativeModel(
      model: SparkChatService.defaultModel,
      apiKey: key,
      systemInstruction: Content.system(SparkAiPrompt.debateCoachSystem),
      generationConfig: GenerationConfig(
        maxOutputTokens: 480,
        temperature: 0.78,
      ),
    );

    try {
      final prompt = _debateUserPrompt(
        topic: topic,
        agreed: agreed,
        whatTheySaid: whatTheySaid,
      );
      var response = await model.generateContent([Content.text(prompt)]);
      var t = response.text?.trim();

      if (_isReplyTooThin(t)) {
        final repairPrompt = _debateUserPrompt(
          topic: topic,
          agreed: agreed,
          whatTheySaid: whatTheySaid,
          repair: true,
          badPreviousReply: t ?? '(empty)',
        );
        response = await model.generateContent([Content.text(repairPrompt)]);
        t = response.text?.trim();
      }

      if (t == null || t.isEmpty) {
        return "Wow, you really jumped in on this topic — I love that you gave it a try! 🦊 Some kids picture the other side in a totally different way. What part of your idea feels strongest to you? I'm excited to hear a bit more! 🦊";
      }
      if (_isReplyTooThin(t)) {
        return "Wow, I can tell you care about this topic! I like how you put your own spin on it. Some friends imagine it another way, and that’s okay in a pretend debate. What would you say back to someone who sees it differently? I’m cheering for you! 🦊";
      }
      return t;
    } on SocketException {
      throw DebateSparkException(_offlineMsg);
    } on GenerativeAIException catch (e) {
      if (_looksLikeNetworkIssue(e.message)) {
        throw DebateSparkException(_offlineMsg);
      }
      throw DebateSparkException(e.message);
    } catch (e) {
      if (e is SocketException) {
        throw DebateSparkException(_offlineMsg);
      }
      final s = e.toString();
      if (_looksLikeNetworkIssue(s)) {
        throw DebateSparkException(_offlineMsg);
      }
      throw DebateSparkException('Buddy had a little hiccup. Try again in a moment! ($e)');
    }
  }
}

class DebateSparkException implements Exception {
  DebateSparkException(this.message);
  final String message;

  @override
  String toString() => message;
}
