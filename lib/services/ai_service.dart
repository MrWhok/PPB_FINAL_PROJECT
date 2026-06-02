import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';
import '../models/message.dart';

class AIService {
  static const String _groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _transcribeUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String _model = 'llama-3.3-70b-versatile';
  static const String _whisperModel = 'whisper-large-v3-turbo';

  /// Sends a recorded audio file to Groq Whisper and returns the transcript.
  /// [language] is 'en' or 'id'.
  Future<String> transcribeAudio({
    required String filePath,
    String language = 'en',
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_transcribeUrl))
      ..headers['Authorization'] = 'Bearer ${Secrets.groqApiKey}'
      ..fields['model'] = _whisperModel
      ..fields['language'] = language
      ..fields['response_format'] = 'json'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['text'] as String? ?? '').trim();
    }
    throw Exception(
        'Whisper API error ${response.statusCode}: ${response.body}');
  }

  Future<String> generateCounterArgument({
    required String userArgument,
    required String topic,
    required String stance,
    String language = 'en',
    List<Message> previousMessages = const [],
  }) async {
    final userStance = stance == 'pro' ? 'PRO (in favor)' : 'CON (against)';
    final aiStance = stance == 'pro' ? 'CON (against)' : 'PRO (in favor)';

    final systemPrompt =
        'You are an expert debate opponent in a formal debate.\n'
        'Topic: "$topic"\n'
        'The human is arguing the $userStance position.\n'
        'You are arguing the $aiStance position.\n'
        'Respond with a sharp, logical counter-argument in 2-4 sentences. '
        'Be confident, direct, and factual. Do not repeat the user\'s words.\n'
        '${_languageInstruction(language)}';

    // Include last 6 messages as conversation context
    final history = previousMessages.length > 6
        ? previousMessages.sublist(previousMessages.length - 6)
        : previousMessages;

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {
            'role': m.role == 'user' ? 'user' : 'assistant',
            'content': m.content,
          }),
      {'role': 'user', 'content': userArgument},
    ];

    final response = await http
        .post(
          Uri.parse(_groqUrl),
          headers: {
            'Authorization': 'Bearer ${Secrets.groqApiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'max_tokens': 300,
            'temperature': 0.8,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['choices'][0]['message']['content'] as String).trim();
    }
    throw Exception('Groq API error ${response.statusCode}: ${response.body}');
  }

  // Returns {score: int, feedback: String}
  Future<Map<String, dynamic>> scoreDebate({
    required String topic,
    required String stance,
    required List<Message> messages,
    String language = 'en',
  }) async {
    final userMessages = messages
        .where((m) => m.role == 'user')
        .map((m) => '- ${m.content}')
        .join('\n');

    final feedbackLang =
        language == 'id' ? 'Write the FEEDBACK in Indonesian.' : '';

    final prompt =
        'You are an expert debate judge. Evaluate the following arguments.\n\n'
        'Topic: "$topic"\n'
        'Debater\'s stance: ${stance.toUpperCase()}\n\n'
        'Debater\'s arguments:\n$userMessages\n\n'
        'Score the debater from 1 to 10 based on: logic, clarity, and persuasiveness.\n'
        '$feedbackLang\n'
        'Respond in this exact format (nothing else):\n'
        'SCORE: <number>\n'
        'FEEDBACK: <one sentence of feedback>';

    final response = await http
        .post(
          Uri.parse(_groqUrl),
          headers: {
            'Authorization': 'Bearer ${Secrets.groqApiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'max_tokens': 100,
            'temperature': 0.3,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Groq API error ${response.statusCode}');
    }

    final text = (jsonDecode(response.body)['choices'][0]['message']['content']
            as String)
        .trim();

    // Parse SCORE and FEEDBACK from response
    final scoreMatch = RegExp(r'SCORE:\s*(\d+)').firstMatch(text);
    final feedbackMatch = RegExp(r'FEEDBACK:\s*(.+)').firstMatch(text);

    final score = int.tryParse(scoreMatch?.group(1) ?? '5') ?? 5;
    final feedback = feedbackMatch?.group(1)?.trim() ?? text;

    return {'score': score.clamp(1, 10), 'feedback': feedback};
  }

  String _languageInstruction(String language) {
    if (language == 'id') {
      return 'IMPORTANT: Respond ONLY in Indonesian (Bahasa Indonesia).';
    }
    return 'IMPORTANT: Respond ONLY in English.';
  }
}
