import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/socket_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chats_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/typing_provider.dart';

import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/message_bubble.dart' hide MessageBubble;

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
  bool _isTyping = false;
  bool _showScrollToBottom = false;
  late SocketClient _socketClient;

  @override
  void initState() {
    super.initState();
    _socketClient = ref.read(socketClientProvider);
    _scrollController.addListener(_onScroll);

    // Safely initialize data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Mark messages as read on entry
      ref.read(messagesProvider(widget.chatId).notifier).markAsRead(widget.chatId);

      // Connect and join room
      await _socketClient.connect();
      if (_socketClient.socket?.connected ?? false) {
        _joinChatRoom();
      } else {
        _socketClient.socket?.once('connect', (_) => _joinChatRoom());
      }
    });
  }

  void _joinChatRoom() {
    _socketClient.joinChat(widget.chatId, (response) {
      if (response['success'] == true && response['messages'] != null) {
        ref
            .read(messagesProvider(widget.chatId).notifier)
            .setMessagesFromSocket(response['messages']);
      }
    });
  }

  @override
  void dispose() {
    _socketClient.leaveChat(widget.chatId);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Show jump-to-bottom button if scrolled up more than 400px
    final isScrolledUp = _scrollController.position.pixels > 400;
    if (isScrolledUp != _showScrollToBottom) {
      setState(() => _showScrollToBottom = isScrolledUp);
    }

    // Pagination: Load more when reaching the top (end of list in reverse)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(messagesProvider(widget.chatId).notifier).loadMoreMessages(widget.chatId);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleTyping() {
    final typingNotifier = ref.read(typingProvider(widget.chatId).notifier);
    if (!_isTyping) {
      _isTyping = true;
      typingNotifier.startTyping();
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_isTyping) {
        _isTyping = false;
        typingNotifier.stopTyping();
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _isTyping = false;
    ref.read(typingProvider(widget.chatId).notifier).stopTyping();

    try {
      await ref
          .read(messagesProvider(widget.chatId).notifier)
          .sendMessage(widget.chatId, content);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final typingState = ref.watch(typingProvider(widget.chatId));
    final chatDetailAsync = ref.watch(chatDetailProvider(widget.chatId));

    final isOthersTyping = typingState.when(
      data: (map) => map.values.any((t) => t),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Chat Support', style: TextStyle(fontSize: 16)),
                  _buildOnlineStatus(chat),
                ],
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
                loading: () => const LinearProgressIndicator(minHeight: 2),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Messages List
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Reverse for chat behavior
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
    final otherUser = chat.participants.firstWhere(
          (p) => p.id != myId,
      orElse: () => chat.participants.first,
    );

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
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            color: isOnline ? Colors.white : Colors.white70,
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
    if (diff.inDays < 7) return "Last seen ${DateFormat('EEEE').format(date)}"; // e.g. "Last seen Monday"

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
              child: Image.network(product.image!, width: 45, height: 45, fit: BoxFit.cover),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text("${product.currency} ${product.price}", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => context.push('/marketplace/products/${product.id}'),
            child: const Text("View", style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("No messages yet."));

  Widget _buildErrorState() => Center(
    child: TextButton(
      onPressed: () => ref.refresh(messagesProvider(widget.chatId)),
      child: const Text("Error loading messages. Retry?"),
    ),
  );

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('Archive Chat'),
          onTap: () async {
            Navigator.pop(context);
            await ref.read(chatsProvider.notifier).archiveChat(widget.chatId);
            if (mounted) context.pop();
          },
        ),
      ),
    );
  }

  void _showMessageOptions(MessageModel message) {
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(messagesProvider(widget.chatId).notifier).deleteMessage(widget.chatId, message.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}