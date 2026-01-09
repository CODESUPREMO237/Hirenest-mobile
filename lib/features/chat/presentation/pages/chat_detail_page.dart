import 'package:flutter/material.dart';
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

    _messageController.clear();

    // Stop typing indicator for others
    _socketClient.socket?.emit('typing', {
      'chatId': widget.chatId,
      'isTyping': false,
    });

    try {
      await ref
          .read(messagesProvider(widget.chatId).notifier)
          .sendMessage(widget.chatId, content);
      _scrollToBottom();
    } catch (e) {
      if (_isDisposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red,
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
      error: (_, __) => false,
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: chatDetailAsync.when(
          data: (chat) => Row(
            children: [
              const CircleAvatar(radius: 18, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chat Support',
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildOnlineStatus(chat),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
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
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Messages List
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isOthersTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isOthersTyping && index == 0) {
                          return const TypingIndicator();
                        }

                        final messageIndex = isOthersTyping ? index - 1 : index;
                        final message = messages[messageIndex];
                        return MessageBubble(
                          message: message,
                          onLongPress: () => _showMessageOptions(message),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
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
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _scrollToBottom,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.arrow_downward, color: Colors.white),
              ),
            ),
        ],
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
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: isOnline ? Colors.white : Colors.white70,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (product.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                product.image!,
                width: 45,
                height: 45,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 45,
                    height: 45,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 20),
                  );
                },
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${product.currency} ${NumberFormat('#,###').format(product.price)}",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 13,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 32),
            ),
            child: const Text("View", style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          "No messages yet",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          "Start the conversation!",
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    ),
  );

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
        const SizedBox(height: 16),
        const Text(
          "Error loading messages",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            if (!_isDisposed && mounted) {
              ref.refresh(messagesProvider(widget.chatId));
            }
          },
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive Chat'),
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
                        backgroundColor: Colors.red,
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy Text'),
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
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Message',
                style: TextStyle(color: Colors.red),
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
                        backgroundColor: Colors.red,
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