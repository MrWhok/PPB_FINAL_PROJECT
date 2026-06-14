import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await _saveUserToFirestore(
      uid: cred.user!.uid,
      name: name,
      email: email,
      photoURL: '',
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<void> _saveUserToFirestore({
    required String uid,
    required String name,
    required String email,
    required String photoURL,
    bool merge = false,
  }) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'uid': uid,
        'name': name,
        'email': email,
        'photoURL': photoURL,
        'goal': '',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: merge),
    );
  }
}
