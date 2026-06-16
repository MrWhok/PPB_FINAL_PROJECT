import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/repository/profile_repository.dart';
import '../../domain/model/user_profile.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  static const _collection = 'users';

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.collection(_collection).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    });
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _firestore
        .collection(_collection)
        .doc(profile.uid)
        .set(profile.toUpdateMap(), SetOptions(merge: true));

    // Keep Firebase Auth displayName/photo in sync where possible.
    final user = _auth.currentUser;
    if (user != null && user.uid == profile.uid) {
      await user.updateDisplayName(profile.name);
      if (profile.photoURL.isNotEmpty) {
        await user.updatePhotoURL(profile.photoURL);
      }
    }
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required File imageFile,
  }) async {
    final ref = _storage.ref().child('avatars/$uid.jpg');
    final task = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }
}
