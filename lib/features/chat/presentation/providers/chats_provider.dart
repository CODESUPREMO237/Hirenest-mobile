import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';

/// AsyncNotifierProvider for chat list
///
/// Provider to fetch details for a specific chat
final chatDetailProvider = FutureProvider.family<ChatModel, String>((ref, chatId) async {
  final repository = ref.read(chatRepositoryProvider);
  return await repository.getChat(chatId);
});

final chatsProvider =
AsyncNotifierProvider<ChatsNotifier, List<ChatModel>>(ChatsNotifier.new);

class ChatsNotifier extends AsyncNotifier<List<ChatModel>> {
  late final ChatRepository _repository;

  @override
  Future<List<ChatModel>> build() async {
    _repository = ref.read(chatRepositoryProvider);
    return loadChats(); // initial load
  }

  /// Load chats from API or database
  Future<List<ChatModel>> loadChats({bool refresh = false}) async {
    if (refresh) state = const AsyncLoading();

    try {
      final fetchedChats = await _repository.getChats(status: 'active');
      state = AsyncData(fetchedChats);
      return fetchedChats;
    } catch (e, st) {
      state = AsyncError(e, st);
      return [];
    }
  }

  /// Archive a chat
  Future<void> archiveChat(String chatId) async {
    try {
      await _repository.archiveChat(chatId);
      final current = state.value ?? [];
      final updated = current.where((chat) => chat.id != chatId).toList();
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }


}
