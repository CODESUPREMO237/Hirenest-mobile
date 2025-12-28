// Chat Model
// ============================================================================
// chat_model.dart
// lib/features/chat/data/models/chat_model.dart
// ============================================================================
import './message_model.dart';

class ChatModel {
  final String id;
  final List<ParticipantModel> participants;
  final ProductInfoModel? product;
  final MessageModel? lastMessage;
  final String status;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participants,
    this.product,
    this.lastMessage,
    required this.status,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      participants: (json['participants'] as List?)
          ?.map((p) => ParticipantModel.fromJson(p))
          .toList() ??
          [],
      product: json['product'] != null ? ProductInfoModel.fromJson(json['product']) : null,
      lastMessage: (json['lastMessage'] != null &&
          json['lastMessage'] is Map &&
          json['lastMessage'].containsKey('content'))
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
      status: json['status']?.toString() ?? 'active',
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  ChatModel copyWith({
    MessageModel? lastMessage,
    DateTime? updatedAt,
    int? unreadCount,
  }) {
    return ChatModel(
      id: id,
      participants: participants,
      product: product,
      lastMessage: lastMessage ?? this.lastMessage,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ParticipantModel {
  final String id;
  final String name;
  final String? avatar;

  ParticipantModel({required this.id, required this.name, this.avatar});

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    // Safely reach into nested user and profile objects
    final userData = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    final profileData = userData?['profile'] is Map ? userData!['profile'] as Map<String, dynamic> : null;

    return ParticipantModel(
      id: (userData?['_id'] ?? userData?['id'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      name: userData?['fullName'] ??
          userData?['displayName'] ??
          profileData?['displayName'] ??
          userData?['email'] ??
          'Unknown User',
      avatar: profileData?['avatar'] ?? userData?['avatar'],
    );
  }
}
class ProductInfoModel {
  final String id;
  final String name;
  final String? image; // The processed single URL
  final double price;
  final String currency;

  ProductInfoModel({
    required this.id,
    required this.name,
    this.image,
    required this.price,
    required this.currency,
  });

  factory ProductInfoModel.fromJson(Map<String, dynamic> json) {
    // 1. Handle price and currency
    double parsedPrice = 0.0;
    String parsedCurrency = 'XAF'; // Default currency

    if (json['price'] != null) {
      if (json['price'] is Map) {
        parsedPrice = (json['price']['amount'] ?? 0).toDouble();
        parsedCurrency = json['price']['currency']?.toString() ?? 'XAF';
      } else {
        parsedPrice = (json['price'] as num).toDouble();
      }
    }

    // 2. Handle nested images array to get a single URL
    String? imageUrl;
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      final firstImage = json['images'][0];
      imageUrl = firstImage is Map ? firstImage['url'] : firstImage.toString();
    } else {
      imageUrl = json['image'] ?? json['primaryImage']?['url'];
    }

    return ProductInfoModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Product',
      image: imageUrl,
      price: parsedPrice,
      currency: parsedCurrency,
    );
  }
}