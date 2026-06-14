import 'package:flutter/foundation.dart';
import '../../domain/repository/auth_repository.dart';

enum RegisterStatus { initial, loading, success, failure }

class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  RegisterViewModel({required AuthRepository repository})
      : _repository = repository;

  RegisterStatus _status = RegisterStatus.initial;
  String? _error;

  RegisterStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == RegisterStatus.loading;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _status = RegisterStatus.loading;
    _error = null;
    notifyListeners();
    try {
      await _repository.signUp(name: name, email: email, password: password);
      _status = RegisterStatus.success;
    } catch (e) {
      _status = RegisterStatus.failure;
      _error = _friendlyError(e.toString());
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _status = RegisterStatus.initial;
    notifyListeners();
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'This email is already registered. Try signing in.';
    }
    if (raw.contains('weak-password')) return 'Password is too weak.';
    if (raw.contains('network')) return 'No internet connection.';
    return 'Something went wrong. Try again.';
  }
}
