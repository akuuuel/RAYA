import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/explore_controller.dart';

/// Modal Buat Catatan Sekitar Gaya Instagram Notes.
/// Menampilkan preview balon pemikiran langsung di atas avatar pengguna saat mengetik.
class CreateNearbyNoteModal {
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF130E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _CreateNearbyNoteSheet(ref: ref),
    );
  }
}

class _CreateNearbyNoteSheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreateNearbyNoteSheet({required this.ref});

  @override
  State<_CreateNearbyNoteSheet> createState() => _CreateNearbyNoteSheetState();
}

class _CreateNearbyNoteSheetState extends State<_CreateNearbyNoteSheet> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  final List<String> _quickMoods = [
    '☕ Ngopi santai',
    '💻 Lagi kerja/tugas',
    '🍕 Kulineran enak',
    '🎵 Denger lagu',
    '🏃 Olahraga',
    '🚗 Macet di jalan',
    '✨ Ada yang luang?',
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final detail = _detailController.text.trim();
      final success = await widget.ref.read(exploreControllerProvider.notifier).postStatus(
            text: text,
            note: detail.isNotEmpty ? detail : null,
          );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan sekitar Anda berhasil dibagikan di peta! (8 Jam)'),
              backgroundColor: Color(0xFF00CEC9),
            ),
          );
        } else {
          // Tampilkan pesan error dari controller state
          final errMsg = widget.ref.read(exploreControllerProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMsg != null && errMsg.isNotEmpty
                  ? 'Gagal: $errMsg'
                  : 'Gagal membagikan catatan. Periksa koneksi & izin akun Anda.'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = widget.ref.watch(authControllerProvider);
    final myProfile = authState.userProfile;
    final displayName = myProfile?.displayName ?? myProfile?.username ?? 'Anda';
    final currentText = _noteController.text;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenMarginHorizontal,
        right: AppSpacing.screenMarginHorizontal,
        top: AppSpacing.s20,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle bar
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Tinggalkan Catatan Sekitar',
              style: AppTextStyles.headlineMedium(color: AppColors.textPrimary).copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'Catatan akan melayang di atas peta dan dilihat pengguna sekitar selama 8 jam.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary).copyWith(fontSize: 12),
            ),
            const SizedBox(height: 24),

            // ==========================================================
            // PREVIEW GAYA INSTAGRAM NOTES (Live Thought Bubble di atas Avatar)
            // ==========================================================
            Column(
              children: [
                // Balon Catatan Interaktif
                Container(
                  constraints: const BoxConstraints(maxWidth: 220, minWidth: 90),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF281E48),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGlow, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    currentText.isEmpty ? 'Bagikan pemikiran Anda...' : currentText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: currentText.isEmpty ? Colors.white54 : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Ekor titik pemikiran
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGlow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGlow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Avatar Pengguna
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Input Teks Catatan Singkat (Maks 60 Karakter)
            TextField(
              controller: _noteController,
              maxLength: 60,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Tulis catatan singkat...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF1A1430),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),

            // Pilihan Cepat Catatan / Mood
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickMoods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final mood = _quickMoods[index];
                  return ActionChip(
                    label: Text(mood),
                    backgroundColor: const Color(0xFF1E1838),
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    onPressed: () {
                      _noteController.text = mood;
                      setState(() {});
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // Catatan Tambahan Opsional (Detail info, wifi, tempat, dll)
            TextField(
              controller: _detailController,
              maxLength: 200,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Detail tempat/info opsional (cth: Di lantai 2 kafe, colokan aman)',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF16112A),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
                counterText: '',
              ),
            ),

            const SizedBox(height: 16),

            // Penjelasan Penyamaran Lokasi 300m
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF00CEC9)),
                const SizedBox(width: 6),
                Text(
                  'Lokasi Anda disamarkan acak radius minimal 300m (UU PDP)',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Tombol Bagikan Catatan
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: currentText.trim().isEmpty || _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Bagikan Catatan ke Peta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

