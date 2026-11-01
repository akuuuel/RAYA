import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/user_status.dart';
import '../controllers/status_controller.dart';
import '../widgets/create_status_modal.dart';
import 'story_viewer_screen.dart';

/// Layar Tab Status resmi RAYA (Menggantikan tab Pantau)
class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return DateFormat('HH:mm').format(date);
    }
  }

  void _openViewer(BuildContext context, List<UserStatus> list, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(statuses: list, initialIndex: index),
      ),
    );
  }

  void _confirmDeleteStatus(BuildContext context, WidgetRef ref, String statusId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Status Ini?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Status Anda akan dihapus untuk semua orang dan tidak dapat dilihat lagi.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(statusControllerProvider.notifier).deleteMyStatus(statusId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Status berhasil dihapus'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(statusControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final myProfile = authState.userProfile;

    final myStatuses = statusState.myStatuses;
    final unviewedList = statusState.recentUnviewedStatuses;
    final viewedList = statusState.viewedStatuses;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Status',
          style: AppTextStyles.headlineMedium(color: AppColors.textPrimary).copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Tulis status teks',
            onPressed: () => CreateStatusModal.show(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(statusControllerProvider.notifier).refresh(),
        color: AppColors.primaryGlow,
        child: statusState.errorMessage != null &&
                statusState.myStatuses.isEmpty &&
                statusState.contactStatuses.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 52, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal memuat status',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusState.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => ref
                            .read(statusControllerProvider.notifier)
                            .refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              children: [
            // 1. Bagian Status Saya
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMarginHorizontal,
                vertical: 4,
              ),
              leading: GestureDetector(
                onTap: () {
                  if (myStatuses.isNotEmpty) {
                    _openViewer(context, myStatuses, 0);
                  } else {
                    CreateStatusModal.show(context, ref);
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(myStatuses.isNotEmpty ? 2.5 : 0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: myStatuses.isNotEmpty ? AppColors.primaryGradient : null,
                      ),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E1B2E),
                        ),
                        child: Center(
                          child: Text(
                            (myProfile?.displayName?.isNotEmpty == true
                                    ? myProfile!.displayName![0]
                                    : myProfile?.username?[0] ?? 'S')
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (myStatuses.isEmpty)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
              title: Text(
                'Status Saya',
                style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                myStatuses.isNotEmpty
                    ? '${myStatuses.length} pembaruan aktif · Ketuk untuk melihat'
                    : 'Ketuk untuk menambahkan pembaruan status',
                style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (myStatuses.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                      tooltip: 'Hapus status saya',
                      onPressed: () => _confirmDeleteStatus(context, ref, myStatuses.first.id),
                    ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryGlow),
                    tooltip: 'Tambah status foto',
                    onPressed: () => CreateStatusModal.show(context, ref),
                  ),
                ],
              ),
              onTap: () {
                if (myStatuses.isNotEmpty) {
                  _openViewer(context, myStatuses, 0);
                } else {
                  CreateStatusModal.show(context, ref);
                }
              },
              onLongPress: () {
                if (myStatuses.isNotEmpty) {
                  _confirmDeleteStatus(context, ref, myStatuses.first.id);
                }
              },
            ),

            const Divider(color: AppColors.surfaceBorder, height: 28),

            // 2. Bagian Pembaruan Terkini (Belum Dilihat - Lingkaran Warna-warni Gradient)
            if (unviewedList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMarginHorizontal,
                  vertical: 6,
                ),
                child: Text(
                  'Pembaruan terkini',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...unviewedList.asMap().entries.map((entry) {
                final idx = entry.key;
                final status = entry.value;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMarginHorizontal,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(2.8),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF6C5CE7),
                          Color(0xFF00CEC9),
                          Color(0xFFA29BFE),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E1B2E),
                      ),
                      child: Center(
                        child: Text(
                          status.userName.isNotEmpty ? status.userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    status.userName,
                    style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _formatTime(status.createdAt),
                    style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  ),
                  onTap: () => _openViewer(context, unviewedList, idx),
                );
              }),
            ],

            // 3. Bagian Pembaruan yang Telah Dilihat (Lingkaran Abu-abu)
            if (viewedList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMarginHorizontal,
                  18,
                  AppSpacing.screenMarginHorizontal,
                  6,
                ),
                child: Text(
                  'Pembaruan yang telah dilihat',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...viewedList.asMap().entries.map((entry) {
                final idx = entry.key;
                final status = entry.value;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMarginHorizontal,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF555566), // Lingkaran abu-abu karena sudah dilihat
                        width: 2.2,
                      ),
                    ),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E1B2E),
                      ),
                      child: Center(
                        child: Text(
                          status.userName.isNotEmpty ? status.userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    status.userName,
                    style: AppTextStyles.titleMedium(color: AppColors.textSecondary),
                  ),
                  subtitle: Text(
                    _formatTime(status.createdAt),
                    style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                  ),
                  onTap: () => _openViewer(context, viewedList, idx),
                );
              }),
            ],
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_edit_status',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primaryGlow,
            onPressed: () => CreateStatusModal.show(context, ref),
            child: const Icon(Icons.edit, size: 20),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab_camera_status',
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => CreateStatusModal.show(context, ref),
            child: const Icon(Icons.camera_alt_rounded),
          ),
        ],
      ),
    );
  }
}

