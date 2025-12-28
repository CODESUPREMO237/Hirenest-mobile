// ============================================================================
// socket_client.dart (Uses Firebase ID Token for Socket.IO)
// lib/core/network/socket_client.dart
// ============================================================================

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

/// Global state for real-time presence
final onlineUsersProvider = StateProvider<Set<String>>((ref) => {});
final lastSeenProvider = StateProvider<Map<String, DateTime>>((ref) => {});

final socketClientProvider = Provider<SocketClient>((ref) {
  return SocketClient(ref);
});

class SocketClient {
  final Ref ref;
  io.Socket? _socket;
  bool _isConnected = false;

  SocketClient(this.ref);

  bool get isConnected => _isConnected;
  io.Socket? get socket => _socket;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      AppLogger.info('Socket already connected');
      return;
    }

    try {
      print('');
      print('🔌 [SocketClient] Initiating connection...');

      final authService = ref.read(authServiceProvider);

      // ✅ Use getIdToken() for Firebase ID Token (for Socket.IO auth)
      final token = await authService.getIdToken();
      print('   🎫 Firebase token: ${token != null ? "✅ Found" : "❌ Not found"}');

      if (token == null) {
        print('   ❌ No Firebase token - cannot connect to socket');
        AppLogger.error('Socket connection failed: No Firebase token found');
        return;
      }

      print('   🔗 Connecting to: ${AppConfig.socketUrl}');

      _socket = io.io(
        AppConfig.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})  // ✅ Firebase ID Token
            .enableForceNew()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _setupListeners();
      _socket?.connect();

      print('   ✅ Socket connection initiated');
      print('');
    } catch (e, stackTrace) {
      print('   ❌ Socket connection error: $e');
      AppLogger.error('Socket connection error', error: e, stackTrace: stackTrace);
    }
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      _isConnected = true;
      print('✅ [SocketClient] Connected to server');
      AppLogger.info('✅ Socket.IO Connected');
    });

    _socket?.onDisconnect((data) {
      _isConnected = false;
      print('❌ [SocketClient] Disconnected from server');
      AppLogger.warning('❌ Socket.IO Disconnected');
    });

    _socket?.onConnectError((error) {
      print('🔥 [SocketClient] Connection error: $error');
      AppLogger.error('Socket connection error', error: error);
    });

    _socket?.onError((error) {
      print('🔥 [SocketClient] Error: $error');
      AppLogger.error('Socket error', error: error);
    });

    // ==================== INTERNAL PRESENCE LISTENERS ====================

    _socket?.on('user:online', (data) {
      final userId = data['userId'] as String;
      print('👥 [SocketClient] User online: $userId');
      ref.read(onlineUsersProvider.notifier).update((state) => {...state, userId});
    });

    _socket?.on('user:offline', (data) {
      final userId = data['userId'] as String;
      final lastSeenStr = data['lastSeen'] as String?;
      print('👥 [SocketClient] User offline: $userId');

      ref.read(onlineUsersProvider.notifier).update(
              (state) => state.where((id) => id != userId).toSet()
      );

      if (lastSeenStr != null) {
        ref.read(lastSeenProvider.notifier).update(
                (state) => {...state, userId: DateTime.parse(lastSeenStr)}
        );
      }
    });
  }

  // ==================== PUBLIC ACTIONS (EMITS) ====================

  void joinChat(String chatId, Function(dynamic) callback) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ [SocketClient] Cannot join chat - not connected');
      return;
    }

    print('💬 [SocketClient] Joining chat: $chatId');
    _socket?.emitWithAck('chat:join', {'chatId': chatId}, ack: (response) {
      print('✅ [SocketClient] Joined chat: $chatId');
      callback(response);
    });
  }

  void leaveChat(String chatId) {
    if (_socket == null || !_socket!.connected) return;

    print('👋 [SocketClient] Leaving chat: $chatId');
    _socket?.emit('chat:leave', {'chatId': chatId});
  }

  void startTyping(String chatId) {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('typing:start', {'chatId': chatId});
  }

  void stopTyping(String chatId) {
    if (_socket == null || !_socket!.connected) return;
    _socket?.emit('typing:stop', {'chatId': chatId});
  }

  void sendMessage(String chatId, String content, String type, Function(dynamic) callback) {
    if (_socket == null || !_socket!.connected) {
      print('⚠️ [SocketClient] Cannot send message - not connected');
      return;
    }

    print('📤 [SocketClient] Sending message to chat: $chatId');
    _socket?.emitWithAck('message:send', {
      'chatId': chatId,
      'content': content,
      'type': type,
    }, ack: (response) {
      print('✅ [SocketClient] Message sent');
      callback(response);
    });
  }

  // ==================== PUBLIC LISTENERS ====================

  void onNewMessage(Function(dynamic) callback) {
    print('👂 [SocketClient] Listening for new messages');
    _socket?.on('message:new', (data) {
      print('📨 [SocketClient] New message received');
      callback(data);
    });
  }

  void onTyping(Function(dynamic) callback) {
    _socket?.on('typing:user', callback);
  }

  void onMessageRead(Function(dynamic) callback) {
    _socket?.on('message:read_receipt', callback);
  }

  void removeListener(String event) {
    _socket?.off(event);
  }

  void removeAllListeners() {
    _socket?.clearListeners();
  }

  // ==================== CLEANUP ====================

  void disconnect() {
    if (_socket != null) {
      print('🔌 [SocketClient] Disconnecting...');
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      print('✅ [SocketClient] Disconnected and disposed');
    }
  }
}

// ============================================================================
// USAGE EXAMPLE
// ============================================================================
/*

// 1. Connect to socket (typically in app startup)
final socketClient = ref.read(socketClientProvider);
await socketClient.connect();

// 2. Join a chat room
socketClient.joinChat(chatId, (response) {
  print('Joined chat: $response');
});

// 3. Listen for new messages
socketClient.onNewMessage((data) {
  final message = Message.fromJson(data);
  // Handle new message
});

// 4. Send a message
socketClient.sendMessage(chatId, 'Hello!', 'text', (response) {
  print('Message sent: $response');
});

// 5. Disconnect when done
socketClient.disconnect();

*/