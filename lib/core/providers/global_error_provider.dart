// ============================================================================
// Global Critical Error Provider
// lib/core/providers/global_error_provider.dart
//
// Only set when a 'critical' flagged request (e.g. currentUserProvider)
// encounters a connection/timeout failure. Auth failures (401) are handled
// separately by the existing ErrorInterceptor logout flow.
// ============================================================================

import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CriticalError {
  final String message;
  final VoidCallback onRetry;

  CriticalError({required this.message, required this.onRetry});
}

/// Holds the error state for a critical, app-blocking failure.
/// null = no critical error; non-null = show the global error overlay.
final globalCriticalErrorProvider = StateProvider<CriticalError?>((ref) => null);
