// ============================================================================
// analytics_service.dart
// lib/core/repositories/analytics_service.dart
// ============================================================================

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      AppLogger.info('Analytics event: $name');
    } catch (e) {
      AppLogger.error('Analytics error', error: e);
    }
  }


  // User events
  Future<void> logLogin(String method) async {
    await logEvent('login', {'method': method});
  }

  Future<void> logSignUp(String method) async {
    await logEvent('sign_up', {'method': method});
  }

  // Job events
  Future<void> logJobView(String jobId) async {
    await logEvent('view_job', {'job_id': jobId});
  }

  Future<void> logJobApplication(String jobId) async {
    await logEvent('apply_job', {'job_id': jobId});
  }

  Future<void> logJobPost(String jobId) async {
    await logEvent('post_job', {'job_id': jobId});
  }

  // Product events
  Future<void> logProductView(String productId) async {
    await logEvent('view_product', {'product_id': productId});
  }

  Future<void> logProductPurchase(String productId, double amount) async {
    await logEvent('purchase', {
      'product_id': productId,
      'value': amount,
      'currency': 'XAF',
    });
  }

  Future<void> logProductListing(String productId) async {
    await logEvent('list_product', {'product_id': productId});
  }

  // Chat events
  Future<void> logChatStart(String chatId) async {
    await logEvent('start_chat', {'chat_id': chatId});
  }

  Future<void> logMessageSent() async {
    await logEvent('send_message', null);
  }

  // Set user properties
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
