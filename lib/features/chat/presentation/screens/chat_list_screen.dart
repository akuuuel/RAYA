import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../../status/domain/entities/user_status.dart';
import '../../../status/presentation/controllers/status_controller.dart';
import '../../../status/presentation/screens/story_viewer_screen.dart';
import '../../../status/presentation/widgets/create_status_modal.dart';
import '../controllers/chat_list_controller.dart';
import 'chat_room_screen.dart';

/// Layar Utama Percakapan & Status Cerita sesuai desain modern (Stories & Chat Filter).
class ChatListScreen extends ConsumerStatefulWidget {
  final VoidCallback onStartNewChat;

  const ChatListScreen({
    super.key,
    required this.onStartNewChat,
  });

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'unread', 'groups'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 2) {
      return 'now';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays == 1 || (now.day - date.day == 1 && diff.inHours < 48)) {
      return 'Kemarin';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatListControllerProvider);
    final statusState = ref.watch(statusControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final myProfile = authState.userProfile;

    final myStatuses = statusState.myStatuses;
    final contactStatuses = statusState.contactStatuses;
    final allConversations = chatState.conversations;

    // Filter berdasarkan kategori tab
    List<Conversation> filteredList = allConversations;
    if (_selectedFilter == 'unread') {
      filteredList = filteredList.where((c) => c.unreadCount > 0).toList();
    } else if (_selectedFilter == 'groups') {
      filteredList = []; // RAYA saat ini 1-on-1 E2EE privat
    }

    // Filter berdasarkan pencarian
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filteredList = filteredList.where((c) {
        final name = (c.otherUser.displayName ?? c.otherUser.username ?? '').toLowerCase();
        final lastContent = (c.lastMessage?.content ?? '').toLowerCase();
        return name.contains(q) || lastContent.contains(q);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Atas: Judul "Messages" & Tombol Tambah Chat
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMarginHorizontal,
                AppSpacing.s16,
                AppSpacing.screenMarginHorizontal,
                AppSpacing.s8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Messages',
                    style: AppTextStyles.headlineMedium(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit_square,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      tooltip: 'Mulai chat baru',
                      onPressed: widget.onStartNewChat,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Kolom Pencarian "Search chats"
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMarginHorizontal,
                vertical: AppSpacing.s8,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Search chats',
                          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 3. Status Bar Horisontal (Story / Status Lingkaran Sinkron dengan Tab Status)
            Container(
              height: 104,
              padding: const EdgeInsets.only(top: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMarginHorizontal),
                itemCount: contactStatuses.length + 1,
                itemBuilder: (context, index) {
                  // Item Pertama: Status Saya (+ Tombol Tambah / Pratinjau Cerita)
                  if (index == 0) {
                    final myName = myProfile?.displayName ?? myProfile?.username ?? 'Anda';
                    final hasMyStatus = myStatuses.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {
                          if (hasMyStatus) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StoryViewerScreen(statuses: myStatuses, initialIndex: 0),
                              ),
                            );
                          } else {
                            CreateStatusModal.show(context, ref);
                          }
                        },
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(hasMyStatus ? 2.5 : 0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: hasMyStatus ? AppColors.primaryGradient : null,
                                    border: hasMyStatus
                                        ? null
                                        : Border.all(color: AppColors.surfaceBorder, width: 2),
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
                                        myName.isNotEmpty ? myName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!hasMyStatus)
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
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const SizedBox(
                              width: 62,
                              child: Text(
                                'Status Saya',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Item 1..N: Status Kontak (Diurutkan: yang belum dilihat terbaru di kiri, setelah dilihat jadi abu-abu)
                  final status = contactStatuses[index - 1];
                  final name = status.userName;
                  final firstName = name.split(' ').first;
                  final isViewed = status.isViewed;

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StoryViewerScreen(
                              statuses: contactStatuses,
                              initialIndex: index - 1,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isViewed
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF6C5CE7),
                                        Color(0xFF00CEC9),
                                        Color(0xFFA29BFE),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              border: isViewed
                                  ? Border.all(
                                      color: const Color(0xFF555566), // Lingkaran abu-abu setelah dilihat
                                      width: 2.2,
                                    )
                                  : null,
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
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    color: isViewed ? Colors.white60 : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 62,
                            child: Text(
                              firstName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isViewed ? AppColors.textMuted : AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: isViewed ? FontWeight.normal : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Filter Kategori Pills: "All", "Unread", "Groups"
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMarginHorizontal,
                vertical: 6,
              ),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('unread', 'Unread'),
                  const SizedBox(width: 8),
                  _buildFilterChip('groups', 'Groups'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 5. Daftar Obrolan (Chat List Items)
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenMarginHorizontal,
                      ),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final conv = filteredList[index];
                        final otherUser = conv.otherUser;
                        final lastMsg = conv.lastMessage;
                        final isUnread = conv.unreadCount > 0;
                        final timeStr = _formatTime(conv.lastMessageAt);

                        // Ambil pesan terakhir langsung dari teks terdekripsi
                        String lastMessageText = 'Percakapan baru';
                        if (lastMsg != null) {
                          String body = lastMsg.content;
                          if (body.startsWith('REPLY:')) {
                            final parts = body.substring(6).split('||');
                            if (parts.length > 2) {
                              body = parts.sublist(2).join('||');
                            }
                          }
                          if (body.startsWith('IMAGE:')) {
                            final parts = body.substring(6).split('||');
                            body = parts.length > 1 && parts[1].trim().isNotEmpty
                                ? '📷 ${parts[1].trim()}'
                                : '📷 Foto';
                          } else if (body.startsWith('AUDIO:')) {
                            body = '🎤 Pesan Suara';
                          } else if (body.startsWith('FILE:')) {
                            final parts = body.substring(5).split('||');
                            body = '📄 ${parts.isNotEmpty ? parts[0] : "Dokumen"}';
                          }

                          if (lastMsg.isOutgoing) {
                            lastMessageText = 'Anda: $body';
                          } else {
                            lastMessageText = body;
                          }
                        }

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(conversation: conv),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: Row(
                              children: [
                                // Avatar dengan Indikator Titik Hijau Online
                                Stack(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 19,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Titik Hijau Online Aktif
                                    Positioned(
                                      bottom: 1,
                                      right: 1,
                                      child: Container(
                                        width: 13,
                                        height: 13,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00E676), // Hijau terang
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.background,
                                            width: 2.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // Nama Kontak & Pesan Terakhir
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        otherUser.displayName ?? otherUser.username ?? 'Kontak',
                                        style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(
                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastMessageText,
                                        style: TextStyle(
                                          color: isUnread
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Kolom Kanan: Waktu & Badge / Centang Status
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: isUnread ? const Color(0xFF3880FF) : AppColors.textMuted,
                                        fontSize: 12,
                                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (isUnread)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF3880FF), // Biru seperti di gambar contoh
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else if (lastMsg != null && lastMsg.isOutgoing)
                                      _buildTrailingStatus(lastMsg.status)
                                    else
                                      const SizedBox(height: 16),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3880FF) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF3880FF) : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textMuted),
        );
      case MessageStatus.sent:
        return const Icon(Icons.done_rounded, size: 16, color: AppColors.textMuted);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded, size: 16, color: AppColors.textMuted);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF4FC3F7));
    }
  }

  Widget _buildEmptyState() {
    if (_selectedFilter == 'groups') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_rounded, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              'Belum Ada Grup Obrolan',
              style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Fitur grup terenkripsi akan segera hadir di RAYA.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Tidak ada hasil untuk "$_searchQuery"',
              style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    if (_selectedFilter == 'unread') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_chat_read_rounded, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Semua pesan telah dibaca',
              style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceBorder,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.mark_chat_unread_outlined,
                size: 38,
                color: AppColors.primaryGlow,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text(
              'Belum Ada Percakapan',
              style: AppTextStyles.headlineMedium(color: AppColors.textPrimary).copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Pesan obrolan Anda dienkripsi end-to-end secara penuh.',
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: widget.onStartNewChat,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Mulai Chat Baru'),
            ),
          ],
        ),
      ),
    );
  }
}
