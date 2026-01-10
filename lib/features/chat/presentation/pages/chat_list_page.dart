// Chat List Page - WITH AUTOMATIC REFRESH
// lib/features/chat/presentation/pages/chat_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chats_provider.dart';
import '../widgets/chat_tile.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Load chats when page is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('📋 [ChatList] Initial load on page open');
        ref.read(chatsProvider.notifier).loadChats(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh chats when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      print('🔄 [ChatList] App resumed - refreshing chats');
      if (mounted) {
        ref.read(chatsProvider.notifier).loadChats(refresh: true);
      }
    }
  }

  Future<void> _onRefresh() async {
    print('🔄 [ChatList] Manual pull-to-refresh');
    await ref.read(chatsProvider.notifier).loadChats(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsProvider);
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          // Unread count badge
          if (unreadCount > 0)
            Badge(
              label: Text('$unreadCount'),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Navigate to notifications or filter unread chats
                },
              ),
            ),

          // Manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh chats',
            onPressed: () {
              ref.read(chatsProvider.notifier).loadChats(refresh: true);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: chatsAsync.when(
          data: (chats) {
            if (chats.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chats yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start chatting with sellers!',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              itemCount: chats.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final chat = chats[index];

                return ChatTile(
                  chat: chat,
                  onTap: () async {
                    print('📱 [ChatList] Opening chat: ${chat.id}');

                    // Navigate to chat detail
                    await context.push('/chats/${chat.id}');

                    // Refresh after returning from chat
                    if (mounted) {
                      print('🔄 [ChatList] Returned from chat - refreshing');
                      ref.read(chatsProvider.notifier).loadChats(refresh: true);
                    }
                  },
                );
              },
            );
          },

          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),

          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(chatsProvider.notifier).loadChats(refresh: true);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}