import 'dart:io';
import '../model/user_profile.dart';

abstract interface class ProfileRepository {
  Stream<UserProfile?> watchProfile(String uid);
  Future<UserProfile?> getProfile(String uid);
  Future<void> updateProfile(UserProfile profile);

  /// Uploads [imageFile] to Cloud Storage and returns the download URL.
  Future<String> uploadAvatar({required String uid, required File imageFile});
}
