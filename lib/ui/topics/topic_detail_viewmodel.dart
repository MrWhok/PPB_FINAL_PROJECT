import 'package:flutter/foundation.dart';
import '../../data/remote/wikipedia_remote_datasource.dart';

import 'dart:io';
import 'dart:async';

class TopicDetailViewModel extends ChangeNotifier {
  final WikipediaRemoteDatasource _datasource;
  final String topicTitle;

  TopicDetailViewModel({
    required this.topicTitle,
    required WikipediaRemoteDatasource datasource,
  }) : _datasource = datasource;

  String? wikipediaSummary;
  String? aiPolishedSummary;
  bool isLoading = true;
  String? errorMessage; // Replaces hasError boolean

  bool get hasError => errorMessage != null;

  Future<void> fetchSummary() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    try {
      final result = await _datasource.getBackgroundContext(topicTitle);
      if (result == null) {
        errorMessage = 'Failed to generate background context or find relevant information.';
      } else {
        wikipediaSummary = result.wikipediaExtract;
        aiPolishedSummary = result.aiPolishedContext;
      }
    } on SocketException {
      errorMessage = 'No internet connection. Please check your network and try again.';
      wikipediaSummary = null;
      aiPolishedSummary = null;
    } on TimeoutException {
      errorMessage = 'Connection timed out. The server took too long to respond.';
      wikipediaSummary = null;
      aiPolishedSummary = null;
    } catch (e) {
      errorMessage = 'An unexpected error occurred: $e';
      wikipediaSummary = null;
      aiPolishedSummary = null;
    }

    isLoading = false;
    notifyListeners();
  }
}
