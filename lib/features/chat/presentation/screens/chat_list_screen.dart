import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/chat_list_controller.dart';
import 'chat_room_screen.dart';

/// Layar Daftar Percakapan Chat Terenkripsi End-to-End (FR-09 s.d. FR-18 & DESIGN.md 7.5).
class ChatListScreen extends ConsumerWidget {
  final VoidCallback onStartNewChat;

  const ChatListScreen({
    super.key,
    required this.onStartNewChat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatListControllerProvider);
    final conversations = chatState.conversations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Chat',
              style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(fontSize: 20),
            ),
            const SizedBox(width: AppSpacing.s8),
            // Ikon gembok E2EE resmi (DESIGN.md 7.5)
            Tooltip(
              message: 'Pesan terenkripsi end-to-end',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: AppColors.primaryGlow,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'E2EE',
                      style: TextStyle(
                        color: AppColors.primaryGlow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Mulai chat baru',
            onPressed: onStartNewChat,
          ),
        ],
      ),
      body: conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMarginHorizontal,
                vertical: AppSpacing.s8,
              ),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final otherUser = conv.otherUser;
                final lastMsg = conv.lastMessage;
                final timeStr = DateFormat('HH:mm').format(conv.lastMessageAt);

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                      vertical: AppSpacing.s4,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: Center(
                        child: Text(
                          (otherUser.displayName?.isNotEmpty == true
                                  ? otherUser.displayName![0]
                                  : otherUser.username?[0] ?? 'U')
                              .toUpperCase(),
                          style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherUser.displayName ?? otherUser.username ?? 'Kontak',
                            style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      lastMsg?.content ?? 'Percakapan dimulai',
                      style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(conversation: conv),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_chat_unread_outlined,
                size: 48,
                color: AppColors.primaryGlow,
                semanticLabel: 'Ikon Ruang Chat Kosong',
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Belum Ada Percakapan',
              style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Pesan teks Anda dienkripsi end-to-end. Server tidak pernah dapat membaca isi pesan Anda.',
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s32),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGlow,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppSpacing.buttonBorderRadius,
                ),
              ),
              onPressed: onStartNewChat,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: Text(
                'Cari Teman & Mulai Chat',
                style: AppTextStyles.labelLarge(color: AppColors.primaryGlow),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
