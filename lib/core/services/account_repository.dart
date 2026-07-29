// ============================================================================
// ACCOUNT REPOSITORY — GDPR, Verification, Saved Searches,
//                      Subscriptions, Matching, Feature Flags, Legal
// lib/core/services/account_repository.dart
// ============================================================================


import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../constants/api_endpoints.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.read(dioProvider));
});

class AccountRepository {
  final Dio dio;
  AccountRepository(this.dio);

  // ======================== GDPR (Phase 6) ========================

  /// Export all user data as JSON
  Future<Map<String, dynamic>> exportMyData() async {
    final response = await dio.get(ApiEndpoints.exportMyData);
    return response.data['data'];
  }

  /// Permanently delete account
  Future<void> deleteMyAccount() async {
    await dio.delete(ApiEndpoints.deleteMyAccount);
  }

  // ======================== VERIFICATION (Phase 7) ========================

  /// Submit a verification request
  Future<Map<String, dynamic>> submitVerification({
    required String type,
    required String label,
    required List<Map<String, String>> documents,
    String? userNote,
  }) async {
    final response = await dio.post(ApiEndpoints.submitVerification, data: {
      'type': type,
      'label': label,
      'documents': documents,
      if (userNote != null) 'userNote': userNote,
    });
    return response.data['data'];
  }

  /// Get my verifications
  Future<List<dynamic>> getMyVerifications() async {
    final response = await dio.get(ApiEndpoints.myVerifications);
    return response.data['data']['verifications'];
  }

  // ======================== SAVED SEARCHES (Phase 8) ========================

  /// Save a search
  Future<Map<String, dynamic>> saveSearch({
    required String searchType,
    required String name,
    required Map<String, dynamic> criteria,
    bool alertsEnabled = true,
  }) async {
    final response = await dio.post(ApiEndpoints.savedSearches, data: {
      'searchType': searchType,
      'name': name,
      'criteria': criteria,
      'alertsEnabled': alertsEnabled,
    });
    return response.data['data'];
  }

  /// Get my saved searches
  Future<List<dynamic>> getMySavedSearches({String? searchType}) async {
    final params = <String, dynamic>{};
    if (searchType != null) params['searchType'] = searchType;
    final response = await dio.get(ApiEndpoints.savedSearches, queryParameters: params);
    return response.data['data']['savedSearches'];
  }

  /// Delete a saved search
  Future<void> deleteSavedSearch(String id) async {
    await dio.delete(ApiEndpoints.savedSearch(id));
  }

  // ======================== SUBSCRIPTIONS (Phase 9) ========================

  /// Get available plans
  Future<List<dynamic>> getPlans() async {
    final response = await dio.get(ApiEndpoints.plans);
    return response.data['data']['plans'];
  }

  /// Subscribe to a plan
  Future<Map<String, dynamic>> subscribe({
    required String planId,
    required String phoneNumber,
  }) async {
    final response = await dio.post(ApiEndpoints.subscribe, data: {
      'planId': planId,
      'phoneNumber': phoneNumber,
    });
    return response.data['data'];
  }

  /// Get my active subscription
  Future<Map<String, dynamic>?> getMySubscription() async {
    final response = await dio.get(ApiEndpoints.mySubscription);
    return response.data['data']['subscription'];
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    await dio.post(ApiEndpoints.cancelSubscription);
  }

  /// Boost a listing
  Future<Map<String, dynamic>> boostListing({
    required String listingId,
    required String listingType,
  }) async {
    final response = await dio.post(ApiEndpoints.boostListing, data: {
      'listingId': listingId,
      'listingType': listingType,
    });
    return response.data['data'];
  }

  // ======================== MATCHING (Phase 10) ========================

  /// Get recommended jobs
  Future<List<dynamic>> getRecommendedJobs({int limit = 20}) async {
    final response = await dio.get(ApiEndpoints.recommendedJobs,
        queryParameters: {'limit': limit});
    return response.data['data']['recommendations'];
  }

  /// Get recommended candidates for a job
  Future<List<dynamic>> getRecommendedCandidates(String jobId,
      {int limit = 20}) async {
    final response = await dio.get(ApiEndpoints.recommendedCandidates(jobId),
        queryParameters: {'limit': limit});
    return response.data['data']['candidates'];
  }

  // ======================== FEATURE FLAGS (Phase 11) ========================

  /// Get resolved feature flags for current user
  Future<Map<String, dynamic>> getMyFeatureFlags() async {
    final response = await dio.get(ApiEndpoints.myFeatureFlags);
    return Map<String, dynamic>.from(response.data['data']['flags']);
  }

  // ======================== LEGAL (Phase 12) ========================

  /// Get legal acceptance status
  Future<Map<String, dynamic>> getLegalStatus() async {
    final response = await dio.get(ApiEndpoints.legalStatus);
    return response.data['data'];
  }

  /// Accept current ToS and Privacy versions
  Future<void> acceptLegal({
    required String tosVersion,
    required String privacyVersion,
  }) async {
    await dio.post(ApiEndpoints.acceptLegal, data: {
      'tosVersion': tosVersion,
      'privacyVersion': privacyVersion,
    });
  }
}
