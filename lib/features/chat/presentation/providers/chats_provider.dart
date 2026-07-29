import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// ✅ ADD THIS for Ref type
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
  Timer? _autoRefreshTimer;

  @override
  Future<List<ChatModel>> build() async {
    _repository = ref.read(chatRepositoryProvider);

    // Set up auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      debugPrint('🔄 Auto-refresh: Loading chats in background...');
      loadChats(refresh: false); // Silent refresh
    });

    // Clean up timer when provider is disposed
    ref.onDispose(() {
      debugPrint('🛑 Disposing chats provider - stopping auto-refresh');
      _autoRefreshTimer?.cancel();
    });

    return loadChats();
  }

  /// Load chats from API or database
  Future<List<ChatModel>> loadChats({bool refresh = false}) async {
    debugPrint('📋 [Chats] loadChats called (refresh: $refresh)');

    if (refresh) {
      state = const AsyncLoading();
    }

    try {
      final fetchedChats = await _repository.getChats(status: 'active');

      // Sort chats by last message time (most recent first)
      fetchedChats.sort((a, b) {
        // Use timestamp from lastMessage, fallback to updatedAt
        final aTime = a.lastMessage?.timestamp ?? a.updatedAt;
        final bTime = b.lastMessage?.timestamp ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });

      debugPrint('✅ [Chats] Loaded ${fetchedChats.length} chats');
      state = AsyncData(fetchedChats);
      return fetchedChats;
    } catch (e, st) {
      debugPrint('❌ [Chats] Error loading chats: $e');
      state = AsyncError(e, st);
      return [];
    }
  }

  /// Update a specific chat in the list (useful after sending a message)
  void updateChat(ChatModel updatedChat) {
    state.whenData((chats) {
      final index = chats.indexWhere((c) => c.id == updatedChat.id);

      if (index != -1) {
        final updatedChats = [...chats];
        updatedChats[index] = updatedChat;

        // Re-sort after update
        updatedChats.sort((a, b) {
          final aTime = a.lastMessage?.timestamp ?? a.updatedAt;
          final bTime = b.lastMessage?.timestamp ?? b.updatedAt;
          return bTime.compareTo(aTime);
        });

        state = AsyncData(updatedChats);
        debugPrint('✅ [Chats] Updated chat: ${updatedChat.id}');
      } else {
        // Chat not in list, refresh to get it
        debugPrint('⚠️ [Chats] Chat ${updatedChat.id} not found, refreshing list');
        loadChats(refresh: false);
      }
    });
  }

  /// Archive a chat
  Future<void> archiveChat(String chatId) async {
    debugPrint('📦 [Chats] Archiving chat: $chatId');

    try {
      await _repository.archiveChat(chatId);

      // Remove from current list
      final current = state.value ?? [];
      final updated = current.where((chat) => chat.id != chatId).toList();

      state = AsyncData(updated);
      debugPrint('✅ [Chats] Chat archived successfully');
    } catch (e, st) {
      debugPrint('❌ [Chats] Error archiving chat: $e');
      state = AsyncError(e, st);
    }
  }

  /// Mark a chat as read (reduce unread count to 0)
  Future<void> markAsRead(String chatId) async {
    try {
      // Update backend
      await _repository.markAsRead(chatId);

      // Update local state
      state.whenData((chats) {
        final updatedChats = chats.map((chat) {
          if (chat.id == chatId) {
            return chat.copyWith(unreadCount: 0);
          }
          return chat;
        }).toList();

        state = AsyncData(updatedChats);
      });

      debugPrint('✅ [Chats] Marked chat as read: $chatId');
    } catch (e) {
      debugPrint('❌ [Chats] Error marking chat as read: $e');
    }
  }

  /// Get total unread count across all chats
  int getTotalUnreadCount() {
    return state.whenOrNull(
      data: (chats) => chats.fold<int>(
        0,
            (sum, chat) => sum + chat.unreadCount,
      ),
    ) ?? 0;
  }
}

/// Helper provider: Get chat by ID
@riverpod
ChatModel? chatById(ChatByIdRef ref, String chatId) {
  final chatsAsync = ref.watch(chatsProvider);

  return chatsAsync.whenOrNull(
    data: (chats) {
      try {
        return chats.firstWhere((chat) => chat.id == chatId);
      } catch (_) {
        return null;
      }
    },
  );
}

/// Helper provider: Total unread messages count
@riverpod
int totalUnreadCount(TotalUnreadCountRef ref) {
  final chatsAsync = ref.watch(chatsProvider);

  return chatsAsync.whenOrNull(
    data: (chats) => chats.fold<int>(
      0,
          (sum, chat) => sum + chat.unreadCount,
    ),
  ) ?? 0;
}