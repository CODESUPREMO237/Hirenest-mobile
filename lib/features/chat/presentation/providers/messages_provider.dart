// lib/features/chat/presentation/providers/messages_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/socket_client.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// AsyncNotifierProvider.family for messages of a chat
/// FIXED: Messages load instantly when you open the chat (like WhatsApp)
final messagesProvider = AsyncNotifierProvider.family<
    MessagesNotifier, List<MessageModel>, String>(MessagesNotifier.new);

class MessagesNotifier
    extends FamilyAsyncNotifier<List<MessageModel>, String> {
  late final ChatRepository _repository;
  int _page = 1;
  bool _hasMore = true;
  bool _isListenerAttached = false;

  String? get _currentUserId {
    final userAsync = ref.read(currentUserProvider);
    return userAsync.value?.id;
  }

  @override
  Future<List<MessageModel>> build(String chatId) async {
    _repository = ref.read(chatRepositoryProvider);

    // Setup Socket Listener FIRST (so real-time messages work immediately)
    _setupSocketListener(chatId);

    // Load messages SYNCHRONOUSLY (no await) - they appear instantly
    // The UI will show loading state briefly, then messages appear
    return fetchInitialMessages(chatId);
  }

  Future<List<MessageModel>> fetchInitialMessages(String chatId) async {
    try {
      _page = 1;
      _hasMore = true;

      // Fetch messages from API
      final paginated = await _repository.getMessages(chatId, page: _page);

      if (paginated.items.length < 20) _hasMore = false;
      _page++;

      // Apply user context (left/right alignment)
      return paginated.items.map((m) => _applyUserContext(m)).toList();
    } catch (e, st) {
      AppLogger.error('Error fetching initial messages', error: e);
      rethrow;
    }
  }

  void _setupSocketListener(String chatId) {
    if (_isListenerAttached) return;

    final socketClient = ref.read(socketClientProvider);
    socketClient.onNewMessage((data) {
      if (data['chatId'] == chatId) {
        final incomingMessage = _applyUserContext(
            MessageModel.fromJson(data['message'])
        );

        final current = state.value ?? [];
        if (!current.any((m) => m.id == incomingMessage.id)) {
          state = AsyncData([incomingMessage, ...current]);
        }
      }
    });
    _isListenerAttached = true;
  }

  void setMessagesFromSocket(dynamic messageData) {
    if (messageData is! List) return;

    try {
      final messages = messageData
          .map((m) => _applyUserContext(MessageModel.fromJson(m)))
          .toList();

      final displayOrder = messages.reversed.toList();
      state = AsyncData(displayOrder);

      _page = 2;
      _hasMore = messages.length >= 20;
    } catch (e) {
      AppLogger.error('Failed to set messages from socket', error: e);
    }
  }

  Future<void> loadMoreMessages(String chatId) async {
    if (state.isLoading || !_hasMore) return;

    try {
      final paginated = await _repository.getMessages(chatId, page: _page);
      final newMessages = paginated.items.map((m) => _applyUserContext(m)).toList();

      if (newMessages.isEmpty) {
        _hasMore = false;
        return;
      }

      _page++;
      final current = state.value ?? [];
      state = AsyncData([...current, ...newMessages]);

      if (newMessages.length < 20) _hasMore = false;
    } catch (e, st) {
      AppLogger.error('Error loading more messages', error: e);
    }
  }

  Future<void> sendMessage(String chatId, String content, {String type = 'text'}) async {
    try {
      final message = await _repository.sendMessage(chatId, content, type: type);

      final current = state.value ?? [];
      final myMessage = _applyUserContext(message);

      if (!current.any((m) => m.id == myMessage.id)) {
        state = AsyncData([myMessage, ...current]);
      }
    } catch (e, st) {
      AppLogger.error('Error sending message', error: e);
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _repository.deleteMessage(messageId);
      final current = state.value ?? [];
      state = AsyncData(current.where((m) => m.id != messageId).toList());
    } catch (e, st) {
      AppLogger.error('Error deleting message', error: e);
    }
  }

  MessageModel _applyUserContext(MessageModel message) {
    final myId = _currentUserId;
    if (myId == null) {
      return message;
    }

    return message.copyWith(
      isMyMessage: message.senderId == myId,
    );
  }

  Future<void> markAsRead(String chatId) async {
    try {
      await _repository.markAsRead(chatId);

      final currentMessages = state.value ?? [];
      state = AsyncData(
          currentMessages.map((m) => m.copyWith(read: true)).toList()
      );
    } catch (e) {
      AppLogger.error('Failed to mark as read', error: e);
    }
  }
}