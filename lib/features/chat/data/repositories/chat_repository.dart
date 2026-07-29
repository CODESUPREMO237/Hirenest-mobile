import 'package:flutter/foundation.dart';
// Chat Repository
// ============================================================================
// chat_repository.dart
// lib/features/chat/data/repositories/chat_repository.dart
// ============================================================================
import '../../../../core/models/paginated_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(dioProvider));
});

class ChatRepository {
  final Dio dio;

  ChatRepository(this.dio);

  Future<List<ChatModel>> getChats({String status = 'active'}) async {
    final response = await dio.get(
      ApiEndpoints.chats,
      queryParameters: {'status': status},
    );

    final chats = response.data['data']['chats'] as List;
    return chats.map((json) => ChatModel.fromJson(json)).toList();
  }

  Future<ChatModel> getChat(String chatId) async {
    final response = await dio.get(ApiEndpoints.chat(chatId));
    return ChatModel.fromJson(response.data['data']['chat']);
  }

  Future<ChatModel> startChatWithProduct(String productId) async {
    final response = await dio.post(ApiEndpoints.startChat(productId));
    return ChatModel.fromJson(response.data['data']['chat']);
  }

  Future<PaginatedResponse<MessageModel>> getMessages(
      String chatId, {
        int page = 1,
        int limit = 50,
      }) async {
    final response = await dio.get(
      ApiEndpoints.chatMessages(chatId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    return PaginatedResponse.fromJson(
      response.data['data'],
          (json) => MessageModel.fromJson(json),
    );
  }

  Future<MessageModel> sendMessage(
      String chatId,
      String content, {
        String type = 'text',
      }) async {
    final response = await dio.post(
      '${ApiEndpoints.chat(chatId)}/messages',
      data: {
        'chatId': chatId,
        'content': content,
        'type': type,
      },
    );

    return MessageModel.fromJson(response.data['data']['message']);
  }
  /// Marks all messages in a specific chat as read
  Future<void> markAsRead(String chatId) async {
    try {
      // Hits DELETE /api/v1/chats/:id/read (matching your ApiEndpoints)
      await dio.put(ApiEndpoints.markAsRead(chatId));
    } catch (e) {
      debugPrint('Error in markAsRead: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      // Ensure you are using the correct endpoint path
      await dio.delete(ApiEndpoints.deleteMessage(messageId));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> archiveChat(String chatId) async {
    await dio.put('${ApiEndpoints.chat(chatId)}/archive');
  }

  Future<int> getUnreadCount() async {
    final response = await dio.get('/chats/unread-count');
    return response.data['data']['count'];
  }



// Use this for BOTH the Profile Page and the Product Detail Page
  Future<String> getOrCreateChat({required String receiverId, String? productId}) async {

    try {
      final response = await dio.post(
        ApiEndpoints.chats,
        data: {
          'receiverId': receiverId,
          if (productId != null) 'productId': productId,
        },
      );

      if (response.data['status'] == 'success') {
        // Return the ID so the UI can context.push('/chats/$id')
        return response.data['data']['chat']['_id'];
      }
      throw Exception(response.data['message'] ?? 'Failed to start chat');
    } catch (e) {
      debugPrint('Chat Repo Error: $e');
      rethrow;
    }
  }


}


