import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../config/secrets.dart';

class TopicContextResult {
  final String? wikipediaExtract;
  final String aiPolishedContext;

  TopicContextResult({
    this.wikipediaExtract,
    required this.aiPolishedContext,
  });
}

class WikipediaRemoteDatasource {
  static final Map<String, TopicContextResult> _contextCache = {};

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
                  'Output the official Wikipedia article title in Indonesian (if the topic is Indonesian) or English (if the topic is English). '
                  'Respond with ONLY the keyword, no quotes, no extra text.'
            },
            {'role': 'user', 'content': topicTitle},
          ],
          'max_tokens': 15,
          'temperature': 0.1,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final keyword = data['choices'][0]['message']['content'].toString().trim();
        if (keyword.isNotEmpty && keyword.length < 50) {
          return keyword;
        }
      }
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (_) {}
    return topicTitle;
  }

  Future<String?> _fetchWikipediaText(String keyword) async {
    // Try Indonesian Wikipedia first
    String? extract = await _queryWikipediaApi('id.wikipedia.org', keyword);
    
    // If not found, fallback to English Wikipedia
    if (extract == null) {
      extract = await _queryWikipediaApi('en.wikipedia.org', keyword);
    }
    
    return extract;
  }

  Future<String?> _queryWikipediaApi(String domain, String keyword) async {
    final searchUrl = Uri.parse(
        'https://$domain/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(keyword)}&utf8=&format=json');
    final searchResponse = await http.get(searchUrl).timeout(const Duration(seconds: 10));

    if (searchResponse.statusCode == 200) {
      final searchData = jsonDecode(searchResponse.body);
      final searchResults = searchData['query']['search'] as List;

      if (searchResults.isNotEmpty) {
        final bestMatchTitle = searchResults.first['title'];
        final summaryUrl = Uri.parse(
            'https://$domain/api/rest_v1/page/summary/${Uri.encodeComponent(bestMatchTitle)}');
        final summaryResponse = await http.get(summaryUrl).timeout(const Duration(seconds: 10));

        if (summaryResponse.statusCode == 200) {
          final summaryData = jsonDecode(summaryResponse.body);
          return summaryData['extract'] as String?;
        }
      }
    }
    return null;
  }

  Future<String> _generateGroqContext(String topic, String? wikiContext) async {
    final prompt = wikiContext != null
        ? 'You are an expert debate coach. The debate topic is: "$topic".\n'
          'Here is some factual background context retrieved from Wikipedia: "$wikiContext".\n'
          'Please rewrite and polish this context so that it is highly relevant for someone preparing for a debate on this specific topic. Keep your explanation SHORT and CONCISE (maximum 2-3 sentences or 1 short paragraph). Answer in the same language as the debate topic.'
        : 'You are an expert debate coach. The debate topic is: "$topic".\n'
          'Generate a SHORT and CONCISE neutral background context (maximum 2-3 sentences) for a debate on this topic relying purely on your own knowledge. Answer in the same language as the debate topic.';

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${Secrets.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1024,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      throw Exception('Failed to generate AI context');
    }
  }

  Future<TopicContextResult?> getBackgroundContext(String topicTitle) async {
    if (_contextCache.containsKey(topicTitle)) {
      return _contextCache[topicTitle];
    }

    try {
      // 1. Extract keyword
      final keyword = await _extractKeyword(topicTitle);

      // 2. Fetch from Wikipedia (Indonesian with English fallback)
      final wikiExtract = await _fetchWikipediaText(keyword);

      // 3. Polish and align using Groq
      final aiPolishedContext = await _generateGroqContext(topicTitle, wikiExtract);

      final result = TopicContextResult(
        wikipediaExtract: wikiExtract,
        aiPolishedContext: aiPolishedContext,
      );

      _contextCache[topicTitle] = result;
      return result;
    } on SocketException {
      rethrow;
    } on TimeoutException {
      rethrow;
    } catch (_) {
      return null;
    }
  }
}
