// Chat List Page - WITH AUTOMATIC REFRESH
// lib/features/chat/presentation/pages/chat_list_page.dart

import 'package:flutter/material.dart';
import '../../../../core/widgets/error_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Load chats when page is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('📋 [ChatList] Initial load on page open');
        ref.read(chatsProvider.notifier).loadChats(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh chats when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 [ChatList] App resumed - refreshing chats');
      if (mounted) {
        ref.read(chatsProvider.notifier).loadChats(refresh: true);
      }
    }
  }

  Future<void> _onRefresh() async {
    debugPrint('🔄 [ChatList] Manual pull-to-refresh');
    await ref.read(chatsProvider.notifier).loadChats(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final chatsAsync = ref.watch(chatsProvider);
    final unreadCount = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Messages',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
        ),
        actions: [
          // Unread count badge
          if (unreadCount > 0)
            Badge(
              label: Text('$unreadCount'),
              backgroundColor: AppColors.error,
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimaryLight),
                onPressed: () {
                  // Navigate to notifications or filter unread chats
                },
              ),
            ),
          // Manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimaryLight),
            tooltip: 'Refresh chats',
            onPressed: () {
              ref.read(chatsProvider.notifier).loadChats(refresh: true);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMutedLight),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedFull,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedFull,
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedFull,
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // trigger rebuild for local filter if needed
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: chatsAsync.when(
                data: (chats) {
                  // Apply local filter based on search
                  final searchQuery = _searchController.text.toLowerCase();
                  final filteredChats = chats.where((chat) {
                    final participantName = chat.participants.isNotEmpty
                        ? chat.participants.first.name.toLowerCase()
                        : '';
                    return participantName.contains(searchQuery);
                  }).toList();

                  if (filteredChats.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: AppColors.textMutedLight,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                _searchController.text.isNotEmpty ? 'No results found' : 'No messages yet',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _searchController.text.isNotEmpty ? 'Try a different name' : 'Start chatting with sellers!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textMutedLight,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredChats.length,
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 80,
                      color: AppColors.borderLight,
                    ),
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      return ChatTile(
                        chat: chat,
                        onTap: () async {
                          debugPrint('📱 [ChatList] Opening chat: ${chat.id}');
                          await context.push('/chats/${chat.id}');
                          if (mounted) {
                            debugPrint('🔄 [ChatList] Returned from chat - refreshing');
                            ref.read(chatsProvider.notifier).loadChats(refresh: true);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, stack) => CustomErrorWidget(error: error, onRetry: () => ref.read(chatsProvider.notifier).loadChats(refresh: true)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}