import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/user_profile.dart';
import '../controllers/auth_controller.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  final String email;

  const CompleteProfileScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  DateTime? _selectedBirthDate;
  String? _usernameError;
  String? _birthDateError;
  bool _isUnder18 = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir Anda',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
        _birthDateError = null;
        _isUnder18 = !UserProfile.calculateLocalIsAdult(picked);
      });
    }
  }

  bool _validateForm() {
    bool valid = true;
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() => _usernameError = 'Username wajib diisi.');
      valid = false;
    } else if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(username)) {
      setState(() => _usernameError = 'Gunakan 3-30 huruf kecil, angka, atau underscore.');
      valid = false;
    } else {
      setState(() => _usernameError = null);
    }

    if (_selectedBirthDate == null) {
      setState(() => _birthDateError = 'Tanggal lahir wajib diisi.');
      valid = false;
    } else {
      setState(() => _birthDateError = null);
    }

    return valid;
  }

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;

    final displayName = _nameController.text.trim().isEmpty
        ? _usernameController.text.trim()
        : _nameController.text.trim();

    final success = await ref.read(authControllerProvider.notifier).completeProfile(
          username: _usernameController.text.trim(),
          displayName: displayName,
          birthDate: _selectedBirthDate!,
        );

    if (!mounted) return;

    if (success) {
      // Kembali ke awal / beranda utama
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Lengkapi Profil',
          style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMarginHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Selamat datang di RAYA',
                style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Lengkapi nama, username, dan tanggal lahir Anda untuk melanjutkan.',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s24),

              // Nama Tampilan
              AppTextField(
                label: 'Nama Tampilan (Opsional)',
                hint: 'Contoh: Rina Pratama',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                semanticsLabel: 'Kolom input nama tampilan',
              ),
              const SizedBox(height: AppSpacing.formFieldSpacing),

              // Username Unik
              AppTextField(
                label: 'Username',
                hint: 'contoh: rina_pratama',
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                errorText: _usernameError,
                onChanged: (_) {
                  if (_usernameError != null) {
                    setState(() => _usernameError = null);
                  }
                },
                semanticsLabel: 'Kolom input username unik',
              ),
              const SizedBox(height: AppSpacing.formFieldSpacing),

              // Tanggal Lahir (DatePicker)
              AppTextField(
                label: 'Tanggal Lahir (Wajib)',
                hint: 'Pilih tanggal lahir',
                controller: _birthDateController,
                readOnly: true,
                onTap: _pickBirthDate,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                errorText: _birthDateError,
                semanticsLabel: 'Tombol pemilih tanggal lahir',
              ),
              const SizedBox(height: AppSpacing.s8),

              // Teks Penjelasan Batas Usia (FR-04 & DESIGN.md 7.4)
              Text(
                'Fitur berbagi lokasi langsung hanya tersedia untuk usia 18 tahun ke atas.',
                style: AppTextStyles.labelSmall(color: AppColors.textMuted),
              ),

              if (_isUnder18) ...[
                const SizedBox(height: AppSpacing.s12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                        semanticLabel: 'Pemberitahuan Batas Usia',
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          'Usia Anda di bawah 18 tahun. Anda tetap dapat menggunakan chat, namun fitur Pantau Lokasi dan Peta Publik dinonaktifkan.',
                          style: AppTextStyles.labelSmall(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (authState.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.s16),
                Text(
                  authState.errorMessage!,
                  style: AppTextStyles.labelSmall(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.s32),

              PrimaryButton(
                text: 'Selesai',
                isLoading: authState.isLoading,
                onPressed: _handleSubmit,
                semanticsLabel: 'Tombol simpan profil dan mulai menggunakan RAYA',
              ),
              const SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }
}
