import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/crypto/crypto_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../moderation/domain/entities/report_ticket.dart';
import '../../../moderation/presentation/widgets/report_modal.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../controllers/chat_list_controller.dart';

/// Ruang Obrolan 1-on-1 Terenkripsi End-to-End sesuai FR-09 s.d. FR-18, FR-41, FR-42 dan DESIGN.md 7.5.
class ChatRoomScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ChatRoomScreen({
    super.key,
    required this.conversation,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _peerPublicKey;
  String? _myPublicKey;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final otherUser = widget.conversation.otherUser;

    final peerKey = await chatRepo.getPeerPublicKey(otherUser.id);
    final myKey = await chatRepo.getOrPublishMyPublicKey();

    final messages = await chatRepo.getMessages(
      widget.conversation.id,
      peerKey ?? myKey,
    );

    if (mounted) {
      setState(() {
        _peerPublicKey = peerKey ?? myKey;
        _myPublicKey = myKey;
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _peerPublicKey == null) return;

    _textController.clear();
    final chatRepo = ref.read(chatRepositoryProvider);

    final sentMessage = await chatRepo.sendMessage(
      conversationId: widget.conversation.id,
      recipientId: widget.conversation.otherUser.id,
      text: text,
      recipientPublicKey: _peerPublicKey!,
    );

    setState(() {
      _messages.add(sentMessage);
    });

    ref.read(chatListControllerProvider.notifier).loadConversations();
    _scrollToBottom();
  }

  void _showSafetyVerificationModal() {
    if (_myPublicKey == null || _peerPublicKey == null) return;

    final safetyNumber = CryptoService.generateSafetyNumber(
      userKeyA: _myPublicKey!,
      userKeyB: _peerPublicKey!,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: AppColors.primaryGlow,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Verifikasi Kode Keamanan (FR-12)',
              style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Cocokkan kode keamanan ini dengan ${widget.conversation.otherUser.displayName ?? 'kontak Anda'} untuk memastikan tidak ada pihak ketiga yang menyisipkan diri (Alur F PRD).',
              style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s24),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0C1B),
                borderRadius: AppSpacing.cardBorderRadius,
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                safetyNumber,
                style: const TextStyle(
                  color: AppColors.primaryGlow,
                  fontSize: 16,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(Message message) {
    if (message.deletedForAll) return;

    final isOutgoing = message.isOutgoing;
    final now = DateTime.now();
    final difference = now.difference(message.createdAt);
    final canDeleteForAll = isOutgoing && difference.inMinutes < 15; // FR-18: batas waktu 15 menit

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canDeleteForAll)
              ListTile(
                leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger),
                title: const Text('Hapus untuk Semua Pihak (FR-18)'),
                subtitle: const Text('Dalam batas 15 menit'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(chatRepositoryProvider).deleteMessageForEveryone(message.id);
                  _loadMessages();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
              title: const Text('Hapus untuk Saya'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(chatRepositoryProvider).deleteMessageForMe(message.id);
                _loadMessages();
              },
            ),
            // FR-41 & FR-42: Laporkan Pesan Ini dengan persetujuan bukti teks terdekripsi
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.warning),
              title: const Text('Laporkan Pesan Ini (FR-41, FR-42)'),
              subtitle: const Text('Kirim aduan dengan bukti teks pesan terdekripsi'),
              onTap: () {
                Navigator.pop(ctx);
                ReportModal.show(
                  context,
                  reportedUserId: isOutgoing ? widget.conversation.otherUser.id : message.senderId,
                  reportType: ReportType.message,
                  targetId: message.id,
                  messagePlaintext: message.decryptedText ?? message.content,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.conversation.otherUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  (otherUser.displayName?.isNotEmpty == true
                          ? otherUser.displayName![0]
                          : otherUser.username?[0] ?? 'K')
                      .toUpperCase(),
                  style: AppTextStyles.labelLarge(color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser.displayName ?? otherUser.username ?? 'Kontak',
                    style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                  ),
                  Text(
                    'Terenkripsi End-to-End',
                    style: AppTextStyles.labelSmall(color: AppColors.primaryGlow),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: 'Verifikasi Kode Keamanan Kontak (FR-12)',
            onPressed: _showSafetyVerificationModal,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.surface,
            onSelected: (action) {
              if (action == 'report_user') {
                ReportModal.show(
                  context,
                  reportedUserId: otherUser.id,
                  reportType: ReportType.profile,
                  targetId: otherUser.id,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report_user',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: AppColors.warning, size: 20),
                    SizedBox(width: 8),
                    Text('Laporkan Kontak (FR-41)', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner E2EE kecil di atas percakapan
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: AppColors.surface.withValues(alpha: 0.6),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 12, color: AppColors.primaryGlow),
                SizedBox(width: 6),
                Text(
                  'Pesan dienkripsi end-to-end. Server tidak dapat membacanya.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGlow))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Mulai percakapan aman.\nPesan dienkripsi dari ujung ke ujung.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenMarginHorizontal,
                          vertical: AppSpacing.s16,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),
          // Bar Input Pesan Teks
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMarginHorizontal,
              vertical: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                top: BorderSide(color: AppColors.surfaceBorder),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0C1B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        style: AppTextStyles.bodyLarge(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan rahasia...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppColors.textPrimary),
                      onPressed: _handleSendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isOutgoing = message.isOutgoing;
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(message),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isOutgoing ? AppColors.primaryGradient : null,
            color: isOutgoing ? null : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
              bottomRight: Radius.circular(isOutgoing ? 4 : 16),
            ),
            border: isOutgoing ? null : Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment:
                isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: AppTextStyles.bodyMedium(
                  color: message.deletedForAll ? AppColors.textMuted : AppColors.textPrimary,
                ).copyWith(fontStyle: message.deletedForAll ? FontStyle.italic : FontStyle.normal),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                  if (isOutgoing) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.status == MessageStatus.read
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 14,
                      color: message.status == MessageStatus.read
                          ? AppColors.primaryGlow
                          : AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
