import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  @override
  Future<void> deleteProfilePhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Remove from Firebase Storage (ignore if file doesn't exist)
    try {
      await FirebaseStorage.instance
          .ref('profile_photos/${user.uid}.jpg')
          .delete();
    } catch (_) {}

    // Clear URL in Firestore and Firebase Auth
    await _firestore.collection('users').doc(user.uid).update({'photoURL': ''});
    await user.updatePhotoURL('');
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Future<void> updateProfile({String? name, String? phoneNumber, String? photoURL}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (photoURL != null) updates['photoURL'] = photoURL;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
    if (name != null) await _auth.currentUser?.updateDisplayName(name);
    if (photoURL != null) await _auth.currentUser?.updatePhotoURL(photoURL);
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
        'phoneNumber': '',
        'goal': '',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: merge),
    );
  }
}