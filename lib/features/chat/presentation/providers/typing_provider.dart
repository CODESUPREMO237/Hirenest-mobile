// lib/features/chat/presentation/providers/typing_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final typingProvider = AsyncNotifierProviderFamily<
    TypingNotifier, Map<String, bool>, String>(
  TypingNotifier.new,
);

class TypingNotifier extends FamilyAsyncNotifier<Map<String, bool>, String> {
  late String chatId;

  @override
  Future<Map<String, bool>> build(String chatId) async {
    this.chatId = chatId;
    return {};
  }

  void startTyping() {
    final current = state.value ?? {};
    state = AsyncData({...current, 'me': true});
  }

  void stopTyping() {
    final current = state.value ?? {};
    state = AsyncData({...current, 'me': false});
  }
}
