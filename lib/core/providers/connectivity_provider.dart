// ============================================================================
// Connectivity Provider
// lib/core/providers/connectivity_provider.dart
//
// Wraps connectivity_plus to expose a simple bool stream for online/offline.
// ============================================================================

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits true when the device has any network interface, false when fully offline.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    // connectivity_plus v7 returns a List<ConnectivityResult>
    return results.any((r) => r != ConnectivityResult.none);
  });
});
