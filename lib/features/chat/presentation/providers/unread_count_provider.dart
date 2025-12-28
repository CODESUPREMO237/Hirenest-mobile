import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/chat_repository.dart';

final unreadCountProvider =
AsyncNotifierProvider<UnreadCountNotifier, int>(UnreadCountNotifier.new);

class UnreadCountNotifier extends AsyncNotifier<int> {
  late final ChatRepository _repository;

  @override
  Future<int> build() async {
    _repository = ref.read(chatRepositoryProvider);
    return fetchUnreadCount();
  }

  Future<int> fetchUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = AsyncData(count);
      return count;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 0;
    }
  }

  Future<void> refresh() async => fetchUnreadCount();
}
