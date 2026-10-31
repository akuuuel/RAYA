import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../data/repositories/mock_chat_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../domain/entities/conversation.dart';
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

  ChatListController(this._repository) : super(const ChatListState()) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final list = await _repository.getConversations();
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
