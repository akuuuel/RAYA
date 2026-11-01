import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/repositories/mock_chat_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (AppConfig.useMock) {
    return MockChatRepository();
  }
  return SupabaseChatRepository();
});

class ChatListState {
  final bool isLoading;
  final List<Conversation> conversations;
  final String? errorMessage;

  const ChatListState({
    this.isLoading = false,
    this.conversations = const [],
    this.errorMessage,
  });

  ChatListState copyWith({
    bool? isLoading,
    List<Conversation>? conversations,
    String? errorMessage,
  }) {
    return ChatListState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      errorMessage: errorMessage,
    );
  }
}

class ChatListController extends StateNotifier<ChatListState> {
  final ChatRepository _repository;
  Timer? _pollingTimer;
  final Set<String> _seenMessageIds = {};
  bool _initializedHistory = false;

  ChatListController(this._repository) : super(const ChatListState()) {
    loadConversations();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollSilently();
    });
  }

  Future<void> _pollSilently() async {
    try {
      final list = await _repository.getConversations();

      if (_initializedHistory) {
        for (final conv in list) {
          final last = conv.lastMessage;
          if (last != null && !last.isOutgoing) {
            if (!_seenMessageIds.contains(last.id)) {
              _seenMessageIds.add(last.id);

              // Tampilkan notifikasi hanya jika pengguna tidak sedang membuka room chat ini
              if (NotificationService.instance.activeConversationId != conv.id) {
                String previewText = 'Mengirim pesan baru';
                final content = last.content;
                if (last.messageType == MessageType.image || content.startsWith('IMAGE:')) {
                  previewText = '📷 Foto';
                } else if (content.startsWith('FILE:')) {
                  previewText = '📎 Dokumen';
                } else if (last.messageType == MessageType.voice || content.startsWith('AUDIO:')) {
                  previewText = '🎙️ Pesan Suara';
                } else if (content.isNotEmpty && !content.startsWith('(') && !content.startsWith('[')) {
                  previewText = content;
                }

                await NotificationService.instance.showNotification(
                  id: last.id.hashCode,
                  title: conv.otherUser.displayName ??
                      conv.otherUser.username ??
                      'Pesan Baru',
                  body: previewText,
                  payload: 'chat:${conv.id}',
                );
              }
            }
          }
        }
      } else {
        for (final conv in list) {
          if (conv.lastMessage != null) {
            _seenMessageIds.add(conv.lastMessage!.id);
          }
        }
        _initializedHistory = true;
      }

      state = state.copyWith(conversations: list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final list = await _repository.getConversations();
      for (final conv in list) {
        if (conv.lastMessage != null) {
          _seenMessageIds.add(conv.lastMessage!.id);
        }
      }
      _initializedHistory = true;
      state = state.copyWith(isLoading: false, conversations: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final chatListControllerProvider =
    StateNotifierProvider<ChatListController, ChatListState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatListController(repo);
});
