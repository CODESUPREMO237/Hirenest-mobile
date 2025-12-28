import 'package:flutter/material.dart';
import '../../data/models/chat_model.dart';
import 'package:timeago/timeago.dart' as timeago;

/// A simple online indicator widget
class OnlineStatus extends StatelessWidget {
  final bool isOnline;

  const OnlineStatus({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final participant = chat.participants.first;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: participant.avatar != null
                ? NetworkImage(participant.avatar!)
                : null,
            child: participant.avatar == null
                ? Text(
              participant.name.isNotEmpty
                  ? participant.name[0].toUpperCase()
                  : 'U',
            )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: const OnlineStatus(isOnline: false), // placeholder
          ),
        ],
      ),
      title: Text(
        participant.name.isNotEmpty ? participant.name : 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        chat.lastMessage?.content ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeago.format(chat.updatedAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
