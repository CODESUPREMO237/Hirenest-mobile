// ============================================================================
// FEATURE PROVIDERS — Phase 6-12 Riverpod Providers
// lib/core/services/feature_providers.dart
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'account_repository.dart';

// ======================== FEATURE FLAGS (Phase 11) ========================
// Global provider that caches flags for the session
final featureFlagsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(accountRepositoryProvider);
  try {
    return await repo.getMyFeatureFlags();
  } catch (_) {
    return {};
  }
});

/// Check if a specific flag is enabled
bool isFeatureEnabled(WidgetRef ref, String flagKey) {
  final flags = ref.watch(featureFlagsProvider);
  return flags.whenOrNull(data: (data) => data[flagKey] == true) ?? false;
}

// ======================== LEGAL STATUS (Phase 12) ========================
final legalStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(accountRepositoryProvider);
  return await repo.getLegalStatus();
});

// ======================== SUBSCRIPTION (Phase 9) ========================
final plansProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(accountRepositoryProvider);
  return await repo.getPlans();
});

final mySubscriptionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.read(accountRepositoryProvider);
  return await repo.getMySubscription();
});

// ======================== SAVED SEARCHES (Phase 8) ========================
final savedSearchesProvider = FutureProvider.family<List<dynamic>, String?>((ref, searchType) async {
  final repo = ref.read(accountRepositoryProvider);
  return await repo.getMySavedSearches(searchType: searchType);
});

// ======================== VERIFICATIONS (Phase 7) ========================
final myVerificationsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(accountRepositoryProvider);
  return await repo.getMyVerifications();
});

// ======================== MATCHING (Phase 10) ========================
final recommendedJobsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.read(accountRepositoryProvider);
  return await repo.getRecommendedJobs();
});
