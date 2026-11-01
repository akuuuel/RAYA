import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Layar Pengaturan dan Pengeditan Profil (Nama, Username, Bio, dan Foto Profil).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  File? _selectedImageFile;
  String? _currentAvatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authControllerProvider).userProfile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _currentAvatarUrl = profile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() {
          _selectedImageFile = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showAvatarPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ubah Foto Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryGlow),
                ),
                title: const Text('Ambil Foto Kamera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryGlow),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (_selectedImageFile != null || (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty))
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  ),
                  title: const Text('Hapus Foto Profil', style: TextStyle(color: AppColors.danger)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedImageFile = null;
                      _currentAvatarUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? finalAvatarUrl = _currentAvatarUrl;

    try {
      // 1. Unggah foto baru jika ada
      if (_selectedImageFile != null) {
        final client = Supabase.instance.client;
        final currentUserId = client.auth.currentUser?.id;

        if (currentUserId != null) {
          try {
            final fileExt = _selectedImageFile!.path.split('.').last;
            final filePath = '$currentUserId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
            final bytes = await _selectedImageFile!.readAsBytes();

            await client.storage.from('avatars').uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt', upsert: true),
            );

            final publicUrl = client.storage.from('avatars').getPublicUrl(filePath);
            finalAvatarUrl = publicUrl;
          } catch (_) {
            // Fallback base64 data jika storage bucket belum disetup
            final bytes = await _selectedImageFile!.readAsBytes();
            final base64String = base64Encode(bytes);
            finalAvatarUrl = 'data:image/jpeg;base64,$base64String';
          }
        }
      }

      // 2. Simpan perubahan ke repository dan database
      final success = await ref.read(authControllerProvider.notifier).updateProfile(
        displayName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: finalAvatarUrl,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Color(0xFF00CEC9),
            ),
          );
          Navigator.pop(context);
        } else {
          final errMsg = ref.read(authControllerProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMsg ?? 'Gagal memperbarui profil.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildAvatarWidget(UserProfile? profile) {
    if (_selectedImageFile != null) {
      return CircleAvatar(
        radius: 54,
        backgroundImage: FileImage(_selectedImageFile!),
      );
    }

    if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      if (_currentAvatarUrl!.startsWith('data:image')) {
        try {
          final base64Data = _currentAvatarUrl!.split(',').last;
          final bytes = base64Decode(base64Data);
          return CircleAvatar(
            radius: 54,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      } else if (_currentAvatarUrl!.startsWith('http')) {
        return CircleAvatar(
          radius: 54,
          backgroundImage: NetworkImage(_currentAvatarUrl!),
        );
      }
    }

    // Default inisial huruf dengan gradien
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: AppColors.primaryGlow, width: 2),
      ),
      child: Center(
        child: Text(
          (profile?.displayName?.isNotEmpty == true
                  ? profile!.displayName![0]
                  : (profile?.username?.isNotEmpty == true
                      ? profile!.username![0]
                      : 'R'))
              .toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.userProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Atur Profil Anda',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMarginHorizontal,
          vertical: AppSpacing.s16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar dengan tombol edit kamera
              Center(
                child: Stack(
                  children: [
                    _buildAvatarWidget(profile),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showAvatarPickerSheet,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00CEC9),
                            border: Border.all(color: AppColors.background, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.black,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _showAvatarPickerSheet,
                child: const Text(
                  'Ganti Foto Profil',
                  style: TextStyle(
                    color: Color(0xFF00CEC9),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Field Nama Tampilan
              _buildSectionTitle('Nama Tampilan'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Nama lengkap Anda',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: const Color(0xFF140F24),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryGlow),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primaryGlow),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama tampilan tidak boleh kosong.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Field Username
              _buildSectionTitle('Username'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'username unik Anda',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: const Color(0xFF140F24),
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF00CEC9)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF00CEC9)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Username minimal 3 karakter.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Field Bio
              _buildSectionTitle('Bio Profil'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bioController,
                maxLength: 150,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tulis bio singkat tentang Anda (cth: Mahasiswa TI & pencinta alam ☕)...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF140F24),
                  counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primaryGlow),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Info Akun Read-only
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF100B1D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Informasi Keamanan & Akun',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${profile?.email ?? "-"}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status Usia: ${profile?.isAdult == true ? "18+ (Dewasa)" : "Di Bawah 18 Tahun"}',
                      style: TextStyle(
                        color: profile?.isAdult == true ? AppColors.success : AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Tombol Simpan
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

