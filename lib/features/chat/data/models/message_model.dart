// Message Model
// ============================================================================
// message_model.dart
// lib/features/chat/data/models/message_model.dart
// ============================================================================
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String type;
  final DateTime timestamp;
  final bool read;
  final bool isMyMessage;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.read,
    required this.isMyMessage,
  });

// lib/features/chat/data/models/message_model.dart

// lib/features/chat/data/models/message_model.dart

  factory MessageModel.fromJson(Map<String, dynamic> json, [String? currentUserId]) {
    String sender = '';
    if (json['sender'] != null) {
      if (json['sender'] is String) {
        sender = json['sender'];
      } else if (json['sender'] is Map) {
        sender = (json['sender']['_id'] ?? json['sender']['id'] ?? '').toString();
      }
    }

    return MessageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      chatId: (json['chat'] ?? json['chatId'] ?? '').toString(),
      senderId: sender,
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      read: json['read'] ?? false,
      // FIX: Compare senderId to currentUserId.
      // If currentUserId is null, fallback to the backend's 'isMyMessage' boolean
      isMyMessage: currentUserId != null
          ? (sender == currentUserId)
          : (json['isMyMessage'] ?? false),
    );
  }

  MessageModel copyWith({
    bool? read,
    bool? isMyMessage,
    String? content,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content ?? this.content,
      type: type,
      timestamp: timestamp,
      read: read ?? this.read,
      isMyMessage: isMyMessage ?? this.isMyMessage,
    );
  }
}