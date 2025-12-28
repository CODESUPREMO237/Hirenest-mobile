// Socket Provider
// =====================================================
// SOCKET PROVIDER
// lib/features/chat/presentation/providers/socket_provider.dart
// =====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/config/app_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final socketProvider = Provider<IO.Socket>((ref) {
  final socket = IO.io(
    AppConfig.socketUrl,
    IO.OptionBuilder()
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
