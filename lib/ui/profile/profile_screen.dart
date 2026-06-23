import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../domain/repository/auth_repository.dart';
import '../../theme/app_theme.dart';
import 'profile_viewmodel.dart';

/// Profile — sekarang memakai ProfileViewModel (kamera/galeri, bio, alamat,
/// goal, hapus foto). Disediakan oleh pemanggil via ChangeNotifierProvider.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _hydrated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _hydrate(ProfileViewModel vm) {
    if (_hydrated) return;
    final p = vm.profile;
    _nameController.text = p?.name ?? '';
    _goalController.text = p?.goal ?? '';
    _bioController.text = p?.bio ?? '';
    _phoneController.text = p?.phone ?? '';
    _addressController.text = p?.address ?? '';
    _hydrated = true;
  }

  Future<void> _save(ProfileViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.saveProfile(
      name: _nameController.text.trim(),
      goal: _goalController.text.trim(),
      bio: _bioController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Profil tersimpan' : (vm.error ?? 'Gagal menyimpan'))),
    );
  }

  void _pickAvatar(ProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppTheme.primary),
              title: const Text('Ambil dari kamera',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                vm.changeAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.primary),
              title: const Text('Pilih dari galeri',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                vm.changeAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemovePhoto(ProfileViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Hapus Foto',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Foto profil akan dihapus.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('HAPUS',
                  style: TextStyle(
                      color: AppTheme.conColor, fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (confirmed == true) await vm.removeAvatar();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Log Out',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Yakin ingin keluar?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log Out',
                  style: TextStyle(color: AppTheme.conColor))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthRepository>().signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    if (!vm.isLoading) _hydrate(vm);

    final email = (vm.profile?.email.isNotEmpty ?? false)
        ? vm.profile!.email
        : (FirebaseAuth.instance.currentUser?.email ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          if (vm.isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primary),
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => _save(vm),
              child: const Text('SAVE',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
        ],
      ),
      body: vm.isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildAvatar(vm)),
              const SizedBox(height: 32),
              _section('ACCOUNT INFO'),
              _field(
                label: 'Display Name',
                controller: _nameController,
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              _readOnly(
                  label: 'Email',
                  value: email,
                  icon: Icons.email_outlined),
              const SizedBox(height: 14),
              _field(
                label: 'Phone Number',
                controller: _phoneController,
                icon: Icons.phone_outlined,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _field(
                label: 'Address',
                controller: _addressController,
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              _section('DEBATE PROFILE'),
              _field(
                label: 'Goal',
                controller: _goalController,
                icon: Icons.flag_outlined,
                hint: 'mis. menang lomba debat tingkat kampus',
              ),
              const SizedBox(height: 14),
              _field(
                label: 'Bio',
                controller: _bioController,
                icon: Icons.notes_outlined,
                maxLines: 3,
                hint: 'Ceritakan sedikit tentang dirimu',
              ),
              const SizedBox(height: 36),
              _logoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ProfileViewModel vm) {
    ImageProvider? imageProvider;
    if (vm.pickedImage != null) {
      imageProvider = FileImage(vm.pickedImage!);
    } else if ((vm.profile?.photoURL ?? '').isNotEmpty) {
      imageProvider = NetworkImage(vm.profile!.photoURL);
    }
    final hasPhoto = imageProvider != null;

    return Column(
      children: [
        Stack(
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
                child: vm.isUploading
                    ? const CircularProgressIndicator(color: AppTheme.primary)
                    : (!hasPhoto
                    ? const Icon(Icons.person,
                    size: 56, color: AppTheme.textSecondary)
                    : null),
              ),
            ),
            GestureDetector(
              onTap: () => _pickAvatar(vm),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.background, width: 2),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        if (hasPhoto)
          TextButton.icon(
            onPressed: () => _confirmRemovePhoto(vm),
            icon: const Icon(Icons.hide_image_outlined,
                color: AppTheme.conColor, size: 16),
            label: const Text('Hapus foto',
                style: TextStyle(color: AppTheme.conColor, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title,
        style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5)),
  );

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
      validator: validator,
    );
  }

  Widget _readOnly({
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
          message: 'Email tidak bisa diubah',
          child: Icon(Icons.lock_outline,
              size: 16, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout_rounded, color: AppTheme.conColor),
        label: const Text('LOG OUT',
            style: TextStyle(
                color: AppTheme.conColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.conColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}