import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../../../core/network/socket_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chats_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/typing_provider.dart';

import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/message_bubble.dart';

import '../../data/models/message_model.dart';
import '../../data/models/chat_model.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final String chatId;

  const ChatDetailPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final _scrollController = ScrollController();
  final _messageController = TextEditingController();
  bool _showScrollToBottom = false;
  late SocketClient _socketClient;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _socketClient = ref.read(socketClientProvider);
    _scrollController.addListener(_onScroll);

    // Immediately start loading messages (no delay)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isDisposed) return;

      // Mark messages as read on entry
      ref.read(messagesProvider(widget.chatId).notifier).markAsRead(widget.chatId);

      // Connect and join room
      await _socketClient.connect();
      if (_socketClient.socket?.connected ?? false) {
        _joinChatRoom();
      } else {
        _socketClient.socket?.once('connect', (_) {
          if (!_isDisposed && mounted) {
            _joinChatRoom();
          }
        });
      }
    });
  }

  void _joinChatRoom() {
    if (_isDisposed || !mounted) return;

    _socketClient.joinChat(widget.chatId, (response) {
      if (!_isDisposed && mounted) {
        if (response['success'] == true && response['messages'] != null) {
          ref
              .read(messagesProvider(widget.chatId).notifier)
              .setMessagesFromSocket(response['messages']);
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _socketClient.leaveChat(widget.chatId);
    _scrollController.dispose();
    _messageController.dispose();

    // ✅ REFRESH CHAT LIST WHEN LEAVING
    // This ensures the chat list shows the latest message
    Future.microtask(() {
      if (mounted) {
        ref.read(chatsProvider.notifier).loadChats(refresh: true);
      }
    });

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isDisposed) return;

    final isScrolledUp = _scrollController.position.pixels > 400;
    if (isScrolledUp != _showScrollToBottom) {
      setState(() => _showScrollToBottom = isScrolledUp);
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(messagesProvider(widget.chatId).notifier).loadMoreMessages(widget.chatId);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && !_isDisposed) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleTyping() {
    if (_isDisposed) return;

    // Emit typing event to OTHER users via socket
    _socketClient.socket?.emit('typing', {
      'chatId': widget.chatId,
      'isTyping': true,
    });

    // Auto-stop typing after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (_isDisposed || !mounted) return;
      _socketClient.socket?.emit('typing', {
        'chatId': widget.chatId,
        'isTyping': false,
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_isDisposed) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Clear input immediately for better UX
    _messageController.clear();

    // Stop typing indicator for others
    _socketClient.socket?.emit('typing', {
      'chatId': widget.chatId,
      'isTyping': false,
    });

    try {
      debugPrint('📤 Sending message: $content');

      // Send the message
      await ref
          .read(messagesProvider(widget.chatId).notifier)
          .sendMessage(widget.chatId, content);

      debugPrint('✅ Message sent successfully');

      // Scroll to bottom to show new message
      _scrollToBottom();

      // ✅ CRITICAL: Update chat list immediately after sending
      // This ensures the chat list shows the new message preview
      if (!_isDisposed && mounted) {
        debugPrint('🔄 Refreshing chat list after sending message...');

        // Use a microtask to avoid provider state conflicts
        Future.microtask(() {
          if (mounted && !_isDisposed) {
            ref.read(chatsProvider.notifier).loadChats(refresh: false);
          }
        });
      }

    } catch (e) {
      debugPrint('❌ Error sending message: $e');

      if (_isDisposed || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final typingState = ref.watch(typingProvider(widget.chatId));
    final chatDetailAsync = ref.watch(chatDetailProvider(widget.chatId));
    final myId = ref.watch(currentUserProvider).value?.id;

    // FIXED: Only show typing if OTHER users (not me) are typing
    final isOthersTyping = typingState.when(
      data: (map) {
        // Filter out my own ID from typing users
        final othersTyping = map.entries
            .where((entry) => entry.key != myId && entry.value == true)
            .isNotEmpty;
        return othersTyping;
      },
      loading: () => false,
      error: (err, stack) => false,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryLight),
          onPressed: () {
            // ✅ Refresh chat list when navigating back
            ref.read(chatsProvider.notifier).loadChats(refresh: true);
            context.pop();
          },
        ),
        title: chatDetailAsync.when(
          data: (chat) {
            final otherUser = chat.participants.firstWhereOrNull((p) => p.id != myId) ?? 
                              (chat.participants.isNotEmpty ? chat.participants.first : null);
            final name = otherUser?.name ?? 'Unknown User';

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.backgroundLight,
                  backgroundImage: otherUser?.avatar != null ? NetworkImage(otherUser!.avatar!) : null,
                  child: otherUser?.avatar == null
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryLight,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      _buildOnlineStatus(chat),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Text('Loading...', style: TextStyle(color: AppColors.textPrimaryLight)),
          error: (err, stack) => const Text('Chat', style: TextStyle(color: AppColors.textPrimaryLight)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimaryLight),
            onPressed: () => _showChatOptions(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Product Context Header
              chatDetailAsync.when(
                data: (chat) => chat.product != null
                    ? _buildProductHeader(chat.product!)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              // Messages List
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: messages.length + (isOthersTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isOthersTyping && index == 0) {
                          return const TypingIndicator();
                        }

                        final messageIndex = isOthersTyping ? index - 1 : index;
                        final message = messages[messageIndex];
                        
                        bool showDateHeader = false;
                        if (messageIndex == messages.length - 1) {
                          showDateHeader = true;
                        } else {
                          final prevMessage = messages[messageIndex + 1];
                          final currentMsgDate = message.timestamp;
                          final prevMsgDate = prevMessage.timestamp;
                          if (currentMsgDate.day != prevMsgDate.day ||
                              currentMsgDate.month != prevMsgDate.month ||
                              currentMsgDate.year != prevMsgDate.year) {
                            showDateHeader = true;
                          }
                        }

                        final bubble = MessageBubble(
                          message: message,
                          onLongPress: () => _showMessageOptions(message),
                        );

                        if (showDateHeader) {
                          return Column(
                            children: [
                              _buildDateHeader(message.timestamp),
                              bubble,
                            ],
                          );
                        }

                        return bubble;
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, stack) => _buildErrorState(),
                ),
              ),

              // Input Field
              ChatInput(
                controller: _messageController,
                onChanged: (_) => _handleTyping(),
                onSend: _sendMessage,
                onAttachment: () {},
              ),
            ],
          ),

          // Jump to Bottom FAB
          if (_showScrollToBottom)
            Positioned(
              bottom: 100,
              right: AppSpacing.lg,
              child: FloatingActionButton.small(
                onPressed: _scrollToBottom,
                backgroundColor: AppColors.surfaceLight,
                elevation: 2,
                child: const Icon(Icons.arrow_downward, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    String dateString;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      dateString = 'Today';
    } else if (msgDate == yesterday) {
      dateString = 'Yesterday';
    } else {
      dateString = DateFormat('MMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Text(
        dateString,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildOnlineStatus(ChatModel chat) {
    final myId = ref.read(currentUserProvider).value?.id;
    if (myId == null) {
      return const SizedBox.shrink();
    }

    final otherUser = chat.participants.firstWhereOrNull(
          (p) => p.id != myId,
    ) ?? (chat.participants.isNotEmpty ? chat.participants.first : null);

    if (otherUser == null) {
      return const SizedBox.shrink();
    }

    final isOnline = ref.watch(onlineUsersProvider).contains(otherUser.id);
    final lastSeenMap = ref.watch(lastSeenProvider);
    final lastSeenTime = lastSeenMap[otherUser.id];

    String statusText = isOnline ? "Online" : "Offline";

    if (!isOnline && lastSeenTime != null) {
      statusText = _formatLastSeen(lastSeenTime);
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? AppColors.success : AppColors.textMutedLight,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            statusText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isOnline ? AppColors.successDark : AppColors.textMutedLight,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatLastSeen(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "Last seen just now";
    if (diff.inHours < 1) return "Last seen ${diff.inMinutes}m ago";
    if (diff.inDays < 1) return "Last seen at ${DateFormat('HH:mm').format(date)}";
    if (diff.inDays < 7) return "Last seen ${DateFormat('EEEE').format(date)}";

    return "Last seen ${DateFormat('MMM d').format(date)}";
  }

  Widget _buildProductHeader(ProductInfoModel product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          if (product.image != null)
            ClipRRect(
              borderRadius: AppSpacing.roundedSm,
              child: Image.network(
                product.image!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 48,
                    height: 48,
                    color: AppColors.backgroundLight,
                    child: const Icon(Icons.image_not_supported, size: 20, color: AppColors.textMutedLight),
                  );
                },
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${product.currency} ${NumberFormat('#,###').format(product.price)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              if (!_isDisposed && mounted) {
                context.push('/marketplace/products/${product.id}');
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              minimumSize: const Size(60, 32),
              side: BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
            ),
            child: const Text("View", style: TextStyle(fontSize: 12, color: AppColors.textPrimaryLight)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
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
          "No messages yet",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "Start the conversation!",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMutedLight,
              ),
        ),
      ],
    ),
  );

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          "Error loading messages",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton.icon(
          onPressed: () {
            if (!_isDisposed && mounted) {
              ref.invalidate(messagesProvider(widget.chatId));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text("Retry"),
        ),
      ],
    ),
  );

  void _showChatOptions() {
    if (_isDisposed) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: AppSpacing.roundedFull,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.archive_outlined, color: AppColors.textPrimaryLight),
              title: Text('Archive Chat', style: TextStyle(color: AppColors.textPrimaryLight)),
              onTap: () async {
                Navigator.pop(context);
                if (_isDisposed || !mounted) return;

                try {
                  await ref.read(chatsProvider.notifier).archiveChat(widget.chatId);
                  if (!_isDisposed && mounted) {
                    context.pop();
                  }
                } catch (e) {
                  if (!_isDisposed && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to archive: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(MessageModel message) {
    if (_isDisposed) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: AppSpacing.roundedFull,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: AppColors.textPrimaryLight),
              title: Text('Copy Text', style: TextStyle(color: AppColors.textPrimaryLight)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                if (!_isDisposed && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Delete Message',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                if (_isDisposed || !mounted) return;

                try {
                  await ref
                      .read(messagesProvider(widget.chatId).notifier)
                      .deleteMessage(widget.chatId, message.id);

                  if (!_isDisposed && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (!_isDisposed && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
