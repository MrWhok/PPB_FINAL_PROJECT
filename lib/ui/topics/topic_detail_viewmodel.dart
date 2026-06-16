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

  String? summary;
  bool isLoading = true;
  String? errorMessage; // Replaces hasError boolean

  bool get hasError => errorMessage != null;

  Future<void> fetchSummary() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    try {
      summary = await _datasource.getSummary(topicTitle);
      if (summary == null || summary!.isEmpty) {
        errorMessage = 'Failed to fetch background context from Wikipedia or page not found.';
      }
    } on SocketException {
      errorMessage = 'No internet connection. Please check your network and try again.';
      summary = null;
    } on TimeoutException {
      errorMessage = 'Connection timed out. The server took too long to respond.';
      summary = null;
    } catch (e) {
      errorMessage = 'An unexpected error occurred: $e';
      summary = null;
    }

    isLoading = false;
    notifyListeners();
  }
}
