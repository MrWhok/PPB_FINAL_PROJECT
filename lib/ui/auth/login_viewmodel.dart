import 'package:flutter/foundation.dart';
import '../../domain/repository/auth_repository.dart';

enum AuthStatus { initial, loading, success, failure }

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  LoginViewModel({required AuthRepository repository})
      : _repository = repository;

  AuthStatus _status = AuthStatus.initial;
  String? _error;

  AuthStatus get status => _status;
  String? get error => _error;
  bool get isLoading => _status == AuthStatus.loading;

  Future<void> signIn({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
    try {
      await _repository.signIn(email: email, password: password);
      _status = AuthStatus.success;
    } catch (e) {
      _status = AuthStatus.failure;
      _error = _friendlyError(e.toString());
    }
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _repository.resetPassword(email);
    } catch (e) {
      _error = _friendlyError(e.toString());
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _status = AuthStatus.initial;
    notifyListeners();
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') ||
        raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    if (raw.contains('network')) return 'No internet connection.';
    return 'Something went wrong. Try again.';
  }
}
