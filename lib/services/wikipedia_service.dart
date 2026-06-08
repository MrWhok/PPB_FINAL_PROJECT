import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';

class WikipediaService {
  /// Extract the main entity/keyword from a conversational topic title
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
        // Fallback to original if AI returns empty or something weird
        if (keyword.isNotEmpty && keyword.length < 50) {
          return keyword;
        }
      }
    } catch (e) {
      // Silently fallback if API fails
    }
    return topicTitle;
  }

  static final Map<String, String> _summaryCache = {};

  Future<String?> getSummary(String topicTitle) async {
    // Return from cache if we already fetched it
    if (_summaryCache.containsKey(topicTitle)) {
      return _summaryCache[topicTitle];
    }

    try {
      // 1. Smart Keyword Extraction using Groq AI
      final keyword = await _extractKeyword(topicTitle);

      // 2. Search for the closest Wikipedia page title using the refined keyword
      final searchUrl = Uri.parse(
          'https://id.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(keyword)}&utf8=&format=json');
      final searchResponse = await http.get(searchUrl);

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        final searchResults = searchData['query']['search'] as List;

        if (searchResults.isNotEmpty) {
          // Get the exact title of the top search result
          final bestMatchTitle = searchResults.first['title'];

          // 3. Fetch the summary for that exact title
          final summaryUrl = Uri.parse(
              'https://id.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(bestMatchTitle)}');
          final summaryResponse = await http.get(summaryUrl);

          if (summaryResponse.statusCode == 200) {
            final summaryData = jsonDecode(summaryResponse.body);
            final extract = summaryData['extract'] as String;
            
            // Save to cache
            _summaryCache[topicTitle] = extract;
            
            return extract;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
