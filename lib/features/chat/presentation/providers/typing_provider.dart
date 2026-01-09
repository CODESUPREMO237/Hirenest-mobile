// lib/features/chat/presentation/providers/typing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/socket_client.dart';

final typingProvider = AsyncNotifierProviderFamily<
    TypingNotifier, Map<String, bool>, String>(
  TypingNotifier.new,
);

class TypingNotifier extends FamilyAsyncNotifier<Map<String, bool>, String> {
  late String chatId;
  bool _listenerAttached = false;

  @override
  Future<Map<String, bool>> build(String chatId) async {
    this.chatId = chatId;

    // Setup socket listener for OTHER users typing
    _setupTypingListener();

    return {};
  }

  void _setupTypingListener() {
    if (_listenerAttached) return;

    final socketClient = ref.read(socketClientProvider);

    // Listen for typing events from OTHER users
    socketClient.socket?.on('user_typing', (data) {
      if (data['chatId'] == chatId) {
        final userId = data['userId'] as String;
        final isTyping = data['isTyping'] as bool;

        // Update state with other user's typing status
        final current = state.value ?? {};
        state = AsyncData({
          ...current,
          userId: isTyping,
        });

        // Auto-clear typing status after 3 seconds
        if (isTyping) {
          Future.delayed(const Duration(seconds: 3), () {
            final currentState = state.value ?? {};
            if (currentState[userId] == true) {
              state = AsyncData({
                ...currentState,
                userId: false,
              });
            }
          });
        }
      }
    });

    _listenerAttached = true;
  }
}