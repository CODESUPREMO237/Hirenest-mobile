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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMyMessage) ...[
              const CircleAvatar(
                radius: 14,
                child: Icon(Icons.person, size: 14),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  crossAxisAlignment: CrossAxisAlignment.end, // Align time/ticks to the right
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectionArea(
                      child: _buildMessageContent(
                        context,
                        message.content,
                        isMyMessage,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isMyMessage) const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }

  /// Builds the WhatsApp-style checkmarks
  Widget _buildStatusIcon() {
    // If read, show blue double checks
    if (message.read) {
      return const Icon(
        Icons.done_all,
        size: 15,
        color: Colors.lightBlueAccent, // WhatsApp Blue
      );
    }

    // If your backend supports "delivered" status, you can check it here
    // Otherwise, show grey double checks for received by server
    return Icon(
      Icons.done_all,
      size: 15,
      color: Colors.white.withOpacity(0.6), // Grey double checks
    );
  }

  Widget _buildMessageContent(BuildContext context, String text, bool isMe) {
    final List<String> parts = text.split('**');

    if (parts.length == 1) {
      return Text(
        text,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 14,
          fontFamily: DefaultTextStyle.of(context).style.fontFamily,
        ),
        children: List.generate(parts.length, (index) {
          final bool isBold = index % 2 != 0;
          return TextSpan(
            text: parts[index],
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              decoration: isBold ? TextDecoration.underline : null,
              backgroundColor: isBold
                  ? (isMe ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05))
                  : null,
            ),
          );
        }),
      ),
    );
  }
}