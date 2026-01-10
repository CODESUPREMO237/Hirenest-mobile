// Message Model - COMPLETE VERSION
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
  final DateTime timestamp; // ✅ Using timestamp, not createdAt
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

  factory MessageModel.fromJson(Map<String, dynamic> json, [String? currentUserId]) {
    // Extract sender ID (can be string or object)
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
          : (json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now()),
      read: json['read'] ?? false,
      // Compare senderId to currentUserId
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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chatId': chatId,
      'sender': senderId,
      'content': content,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'isMyMessage': isMyMessage,
    };
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, content: ${content.length > 20 ? "${content.substring(0, 20)}..." : content}, timestamp: $timestamp, read: $read, isMyMessage: $isMyMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}