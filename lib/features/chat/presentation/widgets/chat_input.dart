// Chat Input

// ============================================================================
// MESSAGE BUBBLE WIDGET
// lib/features/chat/presentation/widgets/message_bubble.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isMyMessage = message.isMyMessage;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment:
          isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMyMessage) ...[
              const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isMyMessage
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                    bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isMyMessage ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            color: isMyMessage
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        if (isMyMessage) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.read ? Icons.done_all : Icons.done,
                            size: 12,
                            color: message.read ? Colors.blue : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isMyMessage) ...[
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CHAT INPUT WIDGET
// lib/features/chat/presentation/widgets/chat_input.dart
// ============================================================================

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;
  final ValueChanged<String>? onChanged;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (onAttachment != null)
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: onAttachment,
                color: Theme.of(context).primaryColor,
              ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}