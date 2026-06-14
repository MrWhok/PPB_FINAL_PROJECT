import 'package:flutter/foundation.dart';
import '../../data/remote/wikipedia_remote_datasource.dart';

class TopicDetailViewModel extends ChangeNotifier {
  final WikipediaRemoteDatasource _datasource;
  final String topicTitle;

  TopicDetailViewModel({
    required this.topicTitle,
    required WikipediaRemoteDatasource datasource,
  }) : _datasource = datasource;

  String? summary;
  bool isLoading = true;
  bool hasError = false;

  Future<void> fetchSummary() async {
    isLoading = true;
    hasError = false;
    notifyListeners();
    summary = await _datasource.getSummary(topicTitle);
    isLoading = false;
    hasError = summary == null || summary!.isEmpty;
    notifyListeners();
  }
}
