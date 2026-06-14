import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<void> signUp({required String name, required String email, required String password});
  Future<void> signIn({required String email, required String password});
  Future<void> resetPassword(String email);
  Future<void> signOut();
}
