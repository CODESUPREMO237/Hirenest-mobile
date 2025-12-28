// Analytics Provider
// lib/features/analytics/presentation/providers/analytics_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/analytics_repository.dart';

// User Analytics Provider
final userAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(analyticsRepositoryProvider);
  return await repository.getUserAnalytics();
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