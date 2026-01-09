import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';

part 'chats_provider.g.dart';

/// Provider to fetch details for a specific chat
@riverpod
Future<ChatModel> chatDetail(ChatDetailRef ref, String chatId) async {
  final repository = ref.read(chatRepositoryProvider);
  return await repository.getChat(chatId);
}

/// Chats list provider with auto-refresh on page return
@riverpod
class Chats extends _$Chats {
  late final ChatRepository _repository;

  @override
  Future<List<ChatModel>> build() async {
    _repository = ref.read(chatRepositoryProvider);
    return loadChats();
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