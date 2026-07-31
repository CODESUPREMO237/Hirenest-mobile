// Analytics Provider
// lib/features/analytics/presentation/providers/analytics_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/analytics_repository.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/global_error_provider.dart';

// User Analytics Provider
final userAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final repository = ref.read(analyticsRepositoryProvider);
    return await repository.getUserAnalytics();
  } catch (e) {
    if (e is DioException) {
      final isConnectionError = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;

      if (isConnectionError) {
        debugPrint('🚨 [userAnalyticsProvider] Critical connection failure — triggering global overlay');
        ref.read(globalCriticalErrorProvider.notifier).state = CriticalError(
          message: 'Unable to connect to the server. Please check your internet connection.',
          onRetry: () => ref.invalidateSelf(),
        );
      }
    }
    rethrow;
  }
});

// Platform Stats Provider (Admin only)
final platformStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(analyticsRepositoryProvider);
  return await repository.getPlatformStats();
});

// Revenue Analytics Provider (Admin only)
final revenueAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(analyticsRepositoryProvider);
  return await repository.getRevenueAnalytics();
});