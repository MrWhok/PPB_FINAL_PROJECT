import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/model/user_profile.dart';
import '../../domain/repository/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;
  final String uid;
  final ImagePicker _picker = ImagePicker();

  ProfileViewModel({required ProfileRepository repository, required this.uid})
      : _repository = repository;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  String? _error;
  String? get error => _error;

  /// Local preview of a freshly picked image before/while it uploads.
  File? _pickedImage;
  File? get pickedImage => _pickedImage;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profile = await _repository.getProfile(uid);
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Picks an image from [source] (camera or gallery), uploads it to Storage,
  /// and immediately persists the new photoURL.
  Future<void> changeAvatar(ImageSource source) async {
    _error = null;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (picked == null) return; // user cancelled

      _pickedImage = File(picked.path);
      _isUploading = true;
      notifyListeners();

      final url =
      await _repository.uploadAvatar(uid: uid, imageFile: _pickedImage!);

      final updated = (_profile ?? _emptyProfile()).copyWith(photoURL: url);
      await _repository.updateProfile(updated);
      _profile = updated;
    } catch (e) {
      _error = 'Failed to update photo: $e';
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Removes the current profile photo (clears photoURL).
  Future<void> removeAvatar() async {
    _error = null;
    _isUploading = true;
    notifyListeners();
    try {
      final updated = (_profile ?? _emptyProfile()).copyWith(photoURL: '');
      await _repository.updateProfile(updated);
      _profile = updated;
      _pickedImage = null;
    } catch (e) {
      _error = 'Failed to remove photo: $e';
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required String name,
    required String goal,
    required String bio,
    required String phone,
    required String address,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final updated = (_profile ?? _emptyProfile()).copyWith(
        name: name,
        goal: goal,
        bio: bio,
        phone: phone,
        address: address,
      );
      await _repository.updateProfile(updated);
      _profile = updated;
      return true;
    } catch (e) {
      _error = 'Failed to save profile: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  UserProfile _emptyProfile() => UserProfile(uid: uid, name: '', email: '');
}