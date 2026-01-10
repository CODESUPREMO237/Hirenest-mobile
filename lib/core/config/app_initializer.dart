// ============================================================================
// app_initializer.dart
// lib/core/config/app_initializer.dart
// ============================================================================
// This file initializes all app services including notifications

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../utils/logger.dart';

final appInitializerProvider = Provider<AppInitializer>((ref) {
  return AppInitializer(ref);
});

class AppInitializer {
  final Ref _ref;
  bool _initialized = false;

  AppInitializer(this._ref);

  /// Initialize all app services
  Future<void> initialize() async {
    if (_initialized) {
      AppLogger.info('App already initialized, skipping...');
      return;
    }

    try {
      AppLogger.info('Starting app initialization...');

      // Initialize notification service
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.initialize();
      AppLogger.info('✅ Notification service initialized');

      // Add other service initializations here
      // Example:
      // await _initializeAnalytics();
      // await _initializeRemoteConfig();

      _initialized = true;
      AppLogger.info('✅ App initialization complete');
    } catch (e, stackTrace) {
      AppLogger.error(
        'App initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool get isInitialized => _initialized;
}