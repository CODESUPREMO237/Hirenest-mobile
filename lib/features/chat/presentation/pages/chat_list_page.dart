// Chat List Page
// lib/features/chat/presentation/pages/chat_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chats_provider.dart';
import '../widgets/chat_tile.dart';
import '../providers/unread_count_provider.dart';


class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          unreadCount.when(
            data: (count) => count > 0
                ? Badge(
              label: Text('$count'),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(chatsProvider.notifier).loadChats(refresh: true);
        },
        child: chatsAsync.when(
          data: (chats) {
            if (chats.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No chats yet'),
                    const SizedBox(height: 8),
                    const Text('Start chatting with sellers!'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return ChatTile(
                  chat: chats[index],
                  onTap: () => context.push('/chats/${chats[index].id}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}