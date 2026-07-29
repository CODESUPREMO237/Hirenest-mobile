// Socket Provider
// =====================================================
// SOCKET PROVIDER
// lib/features/chat/presentation/providers/socket_provider.dart
// =====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../../../core/config/app_config.dart';

final socketProvider = Provider<io.Socket>((ref) {
  final socket = io.io(
    AppConfig.socketUrl,
    io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setExtraHeaders({'authorization': 'Bearer TOKEN'}) // Get from auth
        .build(),
  );

  ref.onDispose(() {
    socket.disconnect();
    socket.dispose();
  });

  return socket;
});

final socketConnectionProvider = StateProvider<bool>((ref) => false);
