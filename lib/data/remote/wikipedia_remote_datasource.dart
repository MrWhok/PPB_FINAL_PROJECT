import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/secrets.dart';

class WikipediaRemoteDatasource {
  static final Map<String, String> _summaryCache = {};

  Future<String> _extractKeyword(String topicTitle) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${Secrets.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a Wikipedia keyword extractor. '
                  'Extract the main entity or core subject from the user\'s sentence. '
                  'Translate it to the official Indonesian Wikipedia article title if possible. '
                  'For example, if user says "ai itu sangat membantu", output "Kecerdasan Buatan". '
                  'Respond with ONLY the keyword, no quotes, no extra text.'
            },
            {'role': 'user', 'content': topicTitle},
          ],
          'max_tokens': 15,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keyword = data['choices'][0]['message']['content'].toString().trim();
        if (keyword.isNotEmpty && keyword.length < 50) {
          return keyword;
        }
      }
    } catch (_) {}
    return topicTitle;
  }

  Future<String?> getSummary(String topicTitle) async {
    if (_summaryCache.containsKey(topicTitle)) {
      return _summaryCache[topicTitle];
    }

    try {
      final keyword = await _extractKeyword(topicTitle);

      final searchUrl = Uri.parse(
          'https://id.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(keyword)}&utf8=&format=json');
      final searchResponse = await http.get(searchUrl);

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        final searchResults = searchData['query']['search'] as List;

        if (searchResults.isNotEmpty) {
          final bestMatchTitle = searchResults.first['title'];
          final summaryUrl = Uri.parse(
              'https://id.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(bestMatchTitle)}');
          final summaryResponse = await http.get(summaryUrl);

          if (summaryResponse.statusCode == 200) {
            final summaryData = jsonDecode(summaryResponse.body);
            final extract = summaryData['extract'] as String;
            _summaryCache[topicTitle] = extract;
            return extract;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
