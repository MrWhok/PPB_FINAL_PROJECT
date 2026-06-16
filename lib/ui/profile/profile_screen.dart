import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../domain/repository/auth_repository.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _photoURL;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await context.read<AuthRepository>().getUserProfile();
    if (!mounted) return;
    setState(() {
      _nameController.text = data?['name'] ?? '';
      _phoneController.text = data?['phoneNumber'] ?? '';
      final url = data?['photoURL'] as String?;
      _photoURL = (url != null && url.isNotEmpty) ? url : null;
      _isLoading = false;
    });
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 512,
    );
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<String?> _uploadPhoto() async {
    if (_pickedImage == null) return null;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
    await ref.putFile(_pickedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      String? newPhotoURL;
      if (_pickedImage != null) newPhotoURL = await _uploadPhoto();

      await context.read<AuthRepository>().updateProfile(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoURL: newPhotoURL,
      );

      if (!mounted) return;
      setState(() {
        if (newPhotoURL != null) _photoURL = newPhotoURL;
        _pickedImage = null;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  Future<void> _confirmDeletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove Photo', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'This will permanently remove your profile photo.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('REMOVE', style: TextStyle(color: AppTheme.conColor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await context.read<AuthRepository>().deleteProfilePhoto();
        if (!mounted) return;
        setState(() {
          _photoURL = null;
          _pickedImage = null;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo removed')),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove photo: $e')),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Log Out', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: AppTheme.conColor)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthRepository>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              _buildAvatar(),
              const SizedBox(height: 32),
              _buildSection('ACCOUNT INFO', [
                _buildField(
                  label: 'Display Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _buildReadOnly(
                  label: 'Email',
                  value: FirebaseAuth.instance.currentUser?.email ?? '',
                  icon: Icons.email_outlined,
                ),
              ]),
              const SizedBox(height: 40),
              _buildLogoutButton(),
              const SizedBox(height: 12),
              if (_photoURL != null || _pickedImage != null)
                _buildRemovePhotoButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider;
    if (_pickedImage != null) {
      imageProvider = FileImage(_pickedImage!);
    } else if (_photoURL != null) {
      imageProvider = NetworkImage(_photoURL!);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border, width: 3),
          ),
          child: CircleAvatar(
            radius: 56,
            backgroundColor: AppTheme.surfaceVar,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 56, color: AppTheme.textSecondary)
                : null,
          ),
        ),
        GestureDetector(
          onTap: _pickPhoto,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.background, width: 2),
            ),
            child: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
      validator: validator,
    );
  }

  Widget _buildReadOnly({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      style: const TextStyle(color: AppTheme.textSecondary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: const Tooltip(
          message: 'Email cannot be changed',
          child: Icon(Icons.lock_outline, size: 16, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout_rounded, color: AppTheme.conColor),
        label: const Text(
          'LOG OUT',
          style: TextStyle(
            color: AppTheme.conColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.conColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildRemovePhotoButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _confirmDeletePhoto,
        icon: const Icon(Icons.hide_image_outlined, color: Colors.red, size: 18),
        label: const Text(
          'REMOVE PROFILE PHOTO',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}