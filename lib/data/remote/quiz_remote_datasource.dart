import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/secrets.dart';
import '../../domain/model/quiz_question.dart';

/// Person C feature — Quiz Mode (AI version)
/// Membuat soal pilihan ganda lewat Groq (model & pola sama dengan
/// AIRemoteDatasource). Output dipaksa JSON lalu di-parse jadi QuizQuestion.
class QuizRemoteDatasource {
  static const String _url =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static const Set<String> _validCategories = {
    'Logical Fallacy',
    'Debate Technique',
    'Topic',
  };

  Future<List<QuizQuestion>> generate({
    required String category,
    int count = 5,
  }) async {
    final subject = _subjectFor(category);
    final mixedNote = category == 'Mixed'
        ? 'Mix the categories across questions. For each question set "category" '
        'to one of exactly: "Logical Fallacy", "Debate Technique", or "Topic".\n'
        : 'Set "category" of every question to "$category".\n';

    final prompt =
        'You are a quiz generator for a debate-learning app.\n'
        'Generate exactly $count multiple-choice questions about $subject.\n'
        'Each question must have exactly 4 options and exactly one correct answer.\n'
        'Vary the difficulty (easy/medium/hard) and make distractors plausible.\n'
        'Write in clear English.\n'
        '$mixedNote'
        'Respond ONLY with a valid JSON object (no markdown, no extra text) of the form:\n'
        '{"questions": [{"question": string, "options": [string, string, string, string], '
        '"correctIndex": number from 0 to 3, "explanation": string, '
        '"difficulty": "easy"|"medium"|"hard", "category": string}]}';

    final response = await http
        .post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer ${Secrets.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.8,
        'max_tokens': 2000,
        'response_format': {'type': 'json_object'},
      }),
    )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception(
          'Quiz API error ${response.statusCode}: ${response.body}');
    }

    final content = (jsonDecode(response.body)['choices'][0]['message']
    ['content'] as String)
        .trim();

    return _parse(content, requestedCategory: category);
  }

  List<QuizQuestion> _parse(String content,
      {required String requestedCategory}) {
    var s = content.trim();
    if (s.startsWith('```')) {
      s = s.replaceAll(RegExp(r'^```[a-zA-Z]*'), '').replaceAll('```', '').trim();
    }

    final decoded = jsonDecode(s);
    final rawList = decoded is Map<String, dynamic>
        ? (decoded['questions'] as List? ?? const [])
        : (decoded as List? ?? const []);

    final result = <QuizQuestion>[];
    var i = 0;
    for (final item in rawList) {
      if (item is! Map<String, dynamic>) continue;

      final options =
      (item['options'] as List? ?? const []).map((e) => e.toString()).toList();
      if (options.length != 4) continue;

      var correct = (item['correctIndex'] as num? ?? 0).toInt();
      if (correct < 0 || correct > 3) correct = 0;

      // tentukan kategori final
      String cat;
      if (requestedCategory == 'Mixed') {
        final aiCat = (item['category'] as String? ?? '').trim();
        cat = _validCategories.contains(aiCat) ? aiCat : 'Topic';
      } else {
        cat = requestedCategory;
      }

      result.add(QuizQuestion(
        questionId: 'ai_${DateTime.now().millisecondsSinceEpoch}_$i',
        category: cat,
        question: (item['question'] as String? ?? '').trim(),
        options: options,
        correctIndex: correct,
        explanation: (item['explanation'] as String? ?? '').trim(),
        difficulty: (item['difficulty'] as String? ?? 'medium').trim(),
      ));
      i++;
    }

    if (result.isEmpty) {
      throw Exception('No valid questions generated');
    }
    return result;
  }

  String _subjectFor(String category) {
    switch (category) {
      case 'Logical Fallacy':
        return 'identifying common logical fallacies in arguments '
            '(ad hominem, straw man, false dilemma, slippery slope, bandwagon, '
            'circular reasoning, red herring, etc.) — present short scenarios '
            'and ask which fallacy applies, or ask for definitions';
      case 'Debate Technique':
        return 'formal debate techniques and rhetoric (rebuttal, signposting, '
            'argument structure of claim-evidence-warrant, burden of proof, '
            'steelmanning, cross-examination)';
      case 'Topic':
        return 'general knowledge useful for debating common motions and current '
            'affairs (technology, environment, education, ethics, the UN SDGs)';
      case 'Mixed':
      default:
        return 'a balanced mix of logical fallacies, debate techniques, and '
            'general debate-topic knowledge';
    }
  }
}