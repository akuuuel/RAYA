import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/crypto/crypto_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../moderation/domain/entities/report_ticket.dart';
import '../../../moderation/presentation/widgets/report_modal.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../controllers/chat_list_controller.dart';
import '../controllers/typing_controller.dart';
import '../widgets/image_viewer_screen.dart';
import '../widgets/quoted_reply_bubble.dart';
import '../widgets/reply_preview_bar.dart';
import '../widgets/voice_recording_bar.dart';

/// Ruang Obrolan 1-on-1 Terenkripsi End-to-End sesuai FR-09 s.d. FR-18, FR-41, FR-42 dan DESIGN.md 7.5.
/// Mendukung pengiriman pesan teks, gambar terenkripsi, dan pesan suara (voice notes).
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
  final FocusNode _inputFocusNode = FocusNode();
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _peerPublicKey;
  String? _myPublicKey;

  // Status Reply Pesan
  Message? _replyingMessage;

  // Status Rekam Suara (Voice Note) - Native
  bool _isRecording = false;
  Timer? _messagePollingTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentRecordPath;

  // Status Pemutar Suara Interaktif
  String? _playingVoiceId;
  bool _audioIsPlaying = false;

  // Typing Indicator
  TypingController? _typingController;
  bool _peerIsTyping = false;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.activeConversationId = widget.conversation.id;
    _loadMessages();
    _startMessagePolling();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingVoiceId = null;
          _audioIsPlaying = false;
        });
      }
    });

    // Inisialisasi Typing Controller
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _typingController = TypingController(
        conversationId: widget.conversation.id,
        currentUserId: user.id,
        onPeerTypingChanged: (isTyping) {
          if (mounted) setState(() => _peerIsTyping = isTyping);
        },
      );
      _typingController!.init();
    }
  }

  void _startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollMessages();
    });
  }

  Future<void> _pollMessages() async {
    if (!mounted || _peerPublicKey == null) return;
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final messages = await chatRepo.getMessages(
        widget.conversation.id,
        _peerPublicKey!,
      );
      final hasNewIncoming = messages.any((m) =>
          !m.isOutgoing && m.status != MessageStatus.read);

      // Cek apakah ada pesan baru ATAU ada perubahan status centang (sent -> delivered -> read)
      bool hasChanges = messages.length != _messages.length;
      if (!hasChanges) {
        for (int i = 0; i < messages.length; i++) {
          if (messages[i].status != _messages[i].status ||
              messages[i].deletedForAll != _messages[i].deletedForAll) {
            hasChanges = true;
            break;
          }
        }
      }

      if (mounted && hasChanges) {
        final isNewCount = messages.length > _messages.length;
        setState(() {
          _messages = messages;
        });
        if (isNewCount) {
          _scrollToBottom();
        }
      }
      if (hasNewIncoming) {
        await chatRepo.markMessagesAsRead(widget.conversation.id);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    NotificationService.instance.activeConversationId = null;
    _typingController?.dispose();
    _messagePollingTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    _inputFocusNode.dispose();
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

    // Update status pesan masuk menjadi 'delivered' (diterima & dibuka)
    await chatRepo.markMessagesAsDelivered(widget.conversation.id);
    // Update menjadi 'read' karena pengguna aktif membaca
    await chatRepo.markMessagesAsRead(widget.conversation.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // ListView reverse: true — posisi 0.0 = bawah (pesan terbaru)
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setReplyMessage(Message message) {
    setState(() {
      _replyingMessage = message;
    });
    _inputFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingMessage = null;
    });
  }

  String _getCleanSnippet(String raw) {
    if (raw.startsWith('REPLY:')) {
      final parts = raw.substring(6).split('||');
      if (parts.length > 2) {
        raw = parts.sublist(2).join('||');
      }
    }
    if (raw.startsWith('IMAGE:')) {
      final parts = raw.substring(6).split('||');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return '📷 ${parts[1].trim()}';
      }
      return '📷 Foto';
    }
    if (raw.startsWith('FILE:')) {
      final parts = raw.substring(5).split('||');
      return '📄 ${parts.isNotEmpty ? parts[0] : "Dokumen"}';
    }
    if (raw.startsWith('AUDIO:')) {
      return '🎤 Pesan Suara';
    }
    if (raw.length > 80) {
      return '${raw.substring(0, 80)}...';
    }
    return raw;
  }

  Future<void> _handleSendMessage({String? customText, MessageType messageType = MessageType.text}) async {
    String text = customText ?? _textController.text.trim();
    if (text.isEmpty || _peerPublicKey == null) return;

    if (customText == null) {
      _textController.clear();
    }

    // Jika sedang membalas pesan tertentu, bungkus dengan format REPLY
    if (_replyingMessage != null) {
      final quotedMsg = _replyingMessage!;
      final quotedName = quotedMsg.isOutgoing
          ? 'Anda'
          : (widget.conversation.otherUser.displayName ??
              widget.conversation.otherUser.username ??
              'Kontak');
      final quotedSnippet = _getCleanSnippet(quotedMsg.content);
      text = 'REPLY:$quotedName||$quotedSnippet||$text';
      _replyingMessage = null;
    }

    setState(() {});
    final chatRepo = ref.read(chatRepositoryProvider);

    final sentMessage = await chatRepo.sendMessage(
      conversationId: widget.conversation.id,
      recipientId: widget.conversation.otherUser.id,
      text: text,
      recipientPublicKey: _peerPublicKey!,
      messageType: messageType,
    );

    setState(() {
      _messages.add(sentMessage);
    });

    ref.read(chatListControllerProvider.notifier).loadConversations();
    _scrollToBottom();
  }

  // =========================================================================
  // FITUR PENGIRIMAN GAMBAR / FILE (NATIVE PICKER)
  // =========================================================================
  void _showMediaPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: AppSpacing.s16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMarginHorizontal),
                child: Text(
                  'Kirim Media atau File',
                  style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.primaryGlow),
                ),
                title: Text('Galeri Foto / Video', style: AppTextStyles.bodyLarge(color: AppColors.textPrimary)),
                subtitle: Text('Pilih dari album foto HP', style: AppTextStyles.labelSmall(color: AppColors.textSecondary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryGlow),
                ),
                title: Text('Kamera', style: AppTextStyles.bodyLarge(color: AppColors.textPrimary)),
                subtitle: Text('Ambil foto atau video langsung', style: AppTextStyles.labelSmall(color: AppColors.textSecondary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.attach_file_rounded, color: AppColors.primaryGlow),
                ),
                title: Text('File (PDF, Dokumen, dll)', style: AppTextStyles.bodyLarge(color: AppColors.textPrimary)),
                subtitle: Text('Pilih file dari penyimpanan HP', style: AppTextStyles.labelSmall(color: AppColors.textSecondary)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickFile();
                },
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );
      if (picked == null) return;
      _showMediaPreviewDialog(File(picked.path), picked.name, isImage: true);
    } catch (e) {
      _showError('Gagal membuka galeri: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );
      if (picked == null) return;
      _showMediaPreviewDialog(File(picked.path), picked.name, isImage: true);
    } catch (e) {
      _showError('Gagal membuka kamera: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      final name = result.files.single.name;
      final sizeKb = (result.files.single.size / 1024).toStringAsFixed(1);
      _showMediaPreviewDialog(file, name, isImage: false, sizeInfo: '$sizeKb KB');
    } catch (e) {
      _showError('Gagal memilih file: $e');
    }
  }

  void _showMediaPreviewDialog(File file, String fileName, {required bool isImage, String? sizeInfo}) {
    final captionCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenMarginHorizontal,
          right: AppSpacing.screenMarginHorizontal,
          top: AppSpacing.s20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: AppSpacing.s16),
            if (isImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: AppSpacing.s12),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0C1B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_rounded, color: AppColors.primaryGlow, size: 30),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sizeInfo ?? 'Dokumen',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            TextField(
              controller: captionCtrl,
              autofocus: false,
              style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: isImage ? 'Tulis pesan bersama foto ini...' : 'Keterangan dokumen (opsional)...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: const Color(0xFF0F0C1B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text('Kirim Terenkripsi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final bytes = await file.readAsBytes();
                    final base64Data = base64Encode(bytes);
                    final caption = captionCtrl.text.trim();

                    if (isImage) {
                      final payload = caption.isNotEmpty ? 'IMAGE:$base64Data||$caption' : 'IMAGE:$base64Data';
                      await _handleSendMessage(
                        customText: payload,
                        messageType: MessageType.image,
                      );
                    } else {
                      final safeSize = sizeInfo ?? 'Dokumen';
                      final payload = caption.isNotEmpty
                          ? 'FILE:$fileName||$safeSize||$base64Data||$caption'
                          : 'FILE:$fileName||$safeSize||$base64Data';
                      await _handleSendMessage(
                        customText: payload,
                        messageType: MessageType.image,
                      );
                    }
                  } catch (e) {
                    _showError('Gagal memproses file: $e');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.danger));
  }

  // =========================================================================
  // FITUR PENGIRIMAN & PEMUTAR PESAN SUARA (VOICE NOTE - E2EE)
  // =========================================================================
  Future<void> _startVoiceRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        _showError('Izin mikrofon diperlukan untuk merekam pesan suara.');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/raya_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: path,
      );

      _currentRecordPath = path;
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      _showError('Gagal memulai rekaman suara: $e');
    }
  }

  Future<void> _cancelVoiceRecording() async {
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    if (_currentRecordPath != null) {
      final f = File(_currentRecordPath!);
      if (f.existsSync()) f.deleteSync();
    }
    setState(() {
      _isRecording = false;
      _currentRecordPath = null;
    });
  }

  Future<void> _sendVoiceRecording(int duration) async {
    setState(() {
      _isRecording = false;
    });

    if (duration < 1) {
      try {
        await _audioRecorder.stop();
      } catch (_) {}
      return;
    }

    try {
      final recordedPath = await _audioRecorder.stop();
      final targetPath = recordedPath ?? _currentRecordPath;

      if (targetPath != null && File(targetPath).existsSync()) {
        final bytes = await File(targetPath).readAsBytes();
        final base64Audio = base64Encode(bytes);
        final minutes = (duration ~/ 60).toString().padLeft(2, '0');
        final seconds = (duration % 60).toString().padLeft(2, '0');
        final durationLabel = '$minutes:$seconds';

        final payload = 'AUDIO:$base64Audio||$durationLabel';

        await _handleSendMessage(
          customText: payload,
          messageType: MessageType.voice,
        );

        File(targetPath).deleteSync();
      }
    } catch (e) {
      _showError('Gagal mengirim rekaman suara: $e');
    }
  }

  Future<void> _togglePlayVoice(Message message, String audioData) async {
    if (_playingVoiceId == message.id && _audioIsPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _audioIsPlaying = false;
      });
      return;
    }

    if (_playingVoiceId == message.id && !_audioIsPlaying) {
      await _audioPlayer.resume();
      setState(() {
        _audioIsPlaying = true;
      });
      return;
    }

    setState(() {
      _playingVoiceId = message.id;
      _audioIsPlaying = true;
    });

    try {
      await _audioPlayer.stop();

      if (audioData.startsWith('AUDIO:')) {
        final base64Part = audioData.substring(6).split('||')[0];
        final bytes = base64Decode(base64Part);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/play_${message.id}.m4a');
        if (!tempFile.existsSync()) {
          await tempFile.writeAsBytes(bytes);
        }
        await _audioPlayer.play(DeviceFileSource(tempFile.path));
      } else if (audioData.startsWith('http')) {
        await _audioPlayer.play(UrlSource(audioData));
      } else if (File(audioData).existsSync()) {
        await _audioPlayer.play(DeviceFileSource(audioData));
      } else {
        // Fallback simulasi jika data hanya berupa label durasi
        await Future.delayed(const Duration(seconds: 3));
        if (mounted && _playingVoiceId == message.id) {
          setState(() {
            _playingVoiceId = null;
            _audioIsPlaying = false;
          });
        }
      }
    } catch (e) {
      _showError('Gagal memutar audio: $e');
      if (mounted) {
        setState(() {
          _playingVoiceId = null;
          _audioIsPlaying = false;
        });
      }
    }
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
    final canDeleteForAll = isOutgoing && difference.inMinutes < 15;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: AppColors.primaryGlow),
              title: const Text('Balas Pesan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _setReplyMessage(message);
              },
            ),
            if (canDeleteForAll)
              ListTile(
                leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger),
                title: const Text('Tarik Pesan untuk Semua Orang (FR-18)', style: TextStyle(color: AppColors.danger)),
                subtitle: const Text('Batas waktu 15 menit sejak dikirim', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(chatRepositoryProvider).deleteMessageForEveryone(message.id);
                  setState(() {
                    final index = _messages.indexWhere((m) => m.id == message.id);
                    if (index != -1) {
                      _messages[index] = _messages[index].copyWith(
                        content: 'Pesan ini telah ditarik',
                        deletedForAll: true,
                      );
                    }
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
              title: const Text('Hapus untuk Saya'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(chatRepositoryProvider).deleteMessageForMe(message.id);
                setState(() {
                  _messages.removeWhere((m) => m.id == message.id);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.warning),
              title: const Text('Laporkan Pesan'),
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
              width: 38,
              height: 38,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser.displayName ?? otherUser.username ?? 'Kontak',
                    style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_peerIsTyping)
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          'sedang mengetik...',
                          style: AppTextStyles.labelSmall(color: AppColors.primaryGlow)
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.lock_rounded, size: 10, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'E2EE Terenkripsi Penuh',
                          style: AppTextStyles.labelSmall(color: AppColors.success),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: 'Verifikasi Kode Keamanan',
            onPressed: _showSafetyVerificationModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Enkripsi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF140F24),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: AppColors.primaryGlow),
                SizedBox(width: 6),
                Text(
                  'Pesan dienkripsi end-to-end. Server tidak dapat membaca isi pesan.',
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
                        reverse: true,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenMarginHorizontal,
                          vertical: AppSpacing.s16,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[_messages.length - 1 - index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),
          // Bar Input Pesan: Reply Preview (jika ada) + Input Teks / Suara
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyingMessage != null)
                ReplyPreviewBar(
                  replyMessage: _replyingMessage!,
                  peerName: widget.conversation.otherUser.displayName ??
                      widget.conversation.otherUser.username ??
                      'Kontak',
                  onCancel: _cancelReply,
                ),
              Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenMarginHorizontal,
                  vertical: AppSpacing.s8,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.surfaceBorder),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: _isRecording
                      ? VoiceRecordingBar(
                          onCancel: _cancelVoiceRecording,
                          onSend: _sendVoiceRecording,
                        )
                      : _buildNormalInputBar(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNormalInputBar() {
    return Row(
      children: [
        // Tombol Lampirkan Media atau File (Galeri, Kamera, Dokumen/PDF)
        IconButton(
          icon: const Icon(Icons.attach_file_rounded, color: AppColors.primaryGlow),
          tooltip: 'Kirim foto, kamera, atau dokumen',
          onPressed: _showMediaPickerSheet,
        ),
        const SizedBox(width: 4),
        // Kolom Input Teks
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
              focusNode: _inputFocusNode,
              style: AppTextStyles.bodyLarge(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Tulis pesan rahasia...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onChanged: (_) {
                _typingController?.onTyping();
              },
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        // Tombol Kirim Teks ATAU Tombol Rekam Suara (Responsif tanpa me-rebuild list chat)
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _textController,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            if (hasText) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.textPrimary),
                  tooltip: 'Kirim pesan',
                  onPressed: () => _handleSendMessage(),
                ),
              );
            } else {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic_rounded, color: AppColors.primaryGlow),
                  tooltip: 'Rekam pesan suara',
                  onPressed: _startVoiceRecording,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildMessageContent(Message message, bool isOutgoing) {
    if (message.deletedForAll) {
      return Text(
        'Pesan ini telah ditarik',
        style: AppTextStyles.bodyMedium(color: AppColors.textMuted).copyWith(fontStyle: FontStyle.italic),
      );
    }

    String raw = message.content;
    String? quotedSender;
    String? quotedSnippet;

    // Parse kutipan balasan (Quoted Reply) jika ada
    if (raw.startsWith('REPLY:')) {
      final parts = raw.substring(6).split('||');
      if (parts.length >= 3) {
        quotedSender = parts[0];
        quotedSnippet = parts[1];
        raw = parts.sublist(2).join('||');
      }
    }

    Widget contentBody;

    // 1. Tipe Dokumen / File (PDF, Dokumen, dll)
    if (raw.startsWith('FILE:')) {
      final parts = raw.substring(5).split('||');
      final fileName = parts.isNotEmpty ? parts[0] : 'Dokumen';
      final fileSize = parts.length > 1 ? parts[1] : '';
      final base64Data = parts.length > 2 ? parts[2] : '';
      final caption = parts.length > 3 ? parts[3] : null;

      final isPdf = fileName.toLowerCase().endsWith('.pdf');

      contentBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () async {
              try {
                if (base64Data.isNotEmpty) {
                  final bytes = base64Decode(base64Data);
                  final tempDir = await getApplicationDocumentsDirectory();
                  final savedFile = File('${tempDir.path}/$fileName');
                  await savedFile.writeAsBytes(bytes);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('File disimpan: ${savedFile.path}'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                }
              } catch (e) {
                _showError('Gagal membuka file: $e');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOutgoing ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF0F0C1B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOutgoing ? Colors.white.withValues(alpha: 0.3) : AppColors.surfaceBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPdf ? AppColors.danger.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                      color: isPdf ? AppColors.danger : AppColors.primaryGlow,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: AppTextStyles.bodyMedium(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (fileSize.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            fileSize,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.download_rounded, color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caption,
              style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
            ),
          ],
        ],
      );
    }
    // 2. Tipe Gambar (Foto dari Galeri, Kamera, atau URL) - Interaktif Klik & Zoom
    else if (message.messageType == MessageType.image || raw.startsWith('IMAGE:')) {
      String? base64Img;
      String? imageUrl;
      String? caption;

      if (raw.startsWith('IMAGE:')) {
        final contentPart = raw.substring(6);
        if (contentPart.contains('||')) {
          final parts = contentPart.split('||');
          base64Img = parts[0];
          caption = parts.sublist(1).join('||');
        } else {
          base64Img = contentPart;
        }
      } else if (raw.contains('||')) {
        final parts = raw.split('||');
        imageUrl = parts[0];
        caption = parts.sublist(1).join('||');
      } else {
        imageUrl = raw;
      }

      Widget imageWidget;
      if (base64Img != null && base64Img.isNotEmpty) {
        try {
          final bytes = base64Decode(base64Img);
          imageWidget = Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 40),
            ),
          );
        } catch (_) {
          imageWidget = const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted));
        }
      } else if (imageUrl != null && imageUrl.startsWith('http')) {
        imageWidget = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 40),
          ),
        );
      } else if (imageUrl != null && File(imageUrl).existsSync()) {
        imageWidget = Image.file(
          File(imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 40),
          ),
        );
      } else {
        imageWidget = Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1E1B2E),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_rounded, color: AppColors.primaryGlow),
              SizedBox(width: 8),
              Text('Gambar Terenkripsi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        );
      }

      final authorName = isOutgoing
          ? 'Anda'
          : (widget.conversation.otherUser.displayName ??
              widget.conversation.otherUser.username ??
              'Kontak');

      contentBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Klik foto untuk membuka fullscreen viewer dengan pinch-to-zoom
          GestureDetector(
            onTap: () {
              ImageViewerScreen.show(
                context,
                base64Data: base64Img,
                imageUrl: imageUrl,
                caption: caption,
                senderName: authorName,
                timestamp: message.createdAt,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220, maxWidth: 240),
                    color: Colors.black26,
                    child: imageWidget,
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              caption,
              style: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
            ),
          ],
        ],
      );
    }
    // 3. Tipe Pesan Suara (Voice Note)
    else if (message.messageType == MessageType.voice || raw.startsWith('AUDIO:')) {
      final isPlaying = _playingVoiceId == message.id && _audioIsPlaying;
      String durationLabel = '00:05';
      if (raw.startsWith('AUDIO:')) {
        final parts = raw.substring(6).split('||');
        if (parts.length > 1 && parts[1].isNotEmpty) {
          durationLabel = parts[1];
        }
      } else if (raw.contains(':')) {
        durationLabel = raw;
      }

      contentBody = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _togglePlayVoice(message, raw),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isOutgoing ? Colors.white.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Waveform Audio Visualizer
              Row(
                children: List.generate(14, (i) {
                  final heights = [8.0, 14.0, 20.0, 10.0, 18.0, 24.0, 16.0, 12.0, 22.0, 15.0, 9.0, 18.0, 12.0, 6.0];
                  final h = heights[i % heights.length];
                  final activeColor = isPlaying ? AppColors.success : Colors.white;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 2.5,
                    height: isPlaying ? (h * (0.8 + ((i + DateTime.now().millisecond ~/ 200) % 3) * 0.2)) : h,
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: (i < 7 && isPlaying) ? 1.0 : 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.mic_none_rounded, size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(
                    durationLabel,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }
    // 4. Pesan Teks Biasa
    else {
      contentBody = Text(
        raw,
        style: AppTextStyles.bodyMedium(
          color: AppColors.textPrimary,
        ),
      );
    }

    // Jika pesan ini merupakan balasan (reply), sertakan QuotedReplyBubble di bagian atas
    if (quotedSender != null && quotedSnippet != null) {
      return Column(
        crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          QuotedReplyBubble(
            senderName: quotedSender,
            contentSnippet: quotedSnippet,
            isOutgoing: isOutgoing,
          ),
          contentBody,
        ],
      );
    }

    return contentBody;
  }

  Widget _buildMessageBubble(Message message) {
    final isOutgoing = message.isOutgoing;
    final timeStr = DateFormat('HH:mm').format(message.createdAt);

    // Swipe to Reply: Geser bubble ke kanan untuk langsung membalas
    return Dismissible(
      key: ValueKey('msg_reply_${message.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        _setReplyMessage(message);
        return false; // Jangan hapus pesan dari daftar obrolan
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.reply_rounded,
            color: AppColors.primaryGlow,
            size: 20,
          ),
        ),
      ),
      child: Align(
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
              crossAxisAlignment: isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildMessageContent(message, isOutgoing),
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
                      _buildStatusIcon(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Menampilkan ikon status centang pesan (FR-16)
  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.textMuted,
          ),
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.done_rounded,
          size: 14,
          color: AppColors.textMuted,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all_rounded,
          size: 14,
          color: AppColors.textMuted,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all_rounded,
          size: 14,
          color: Color(0xFF4FC3F7), // Biru terang
        );
    }
  }
}
