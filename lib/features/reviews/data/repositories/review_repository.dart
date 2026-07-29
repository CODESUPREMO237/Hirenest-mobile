import 'package:flutter/foundation.dart';
// lib/features/reviews/data/repositories/review_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_model.dart';

class ReviewRepository {
  final Dio _dio;

  ReviewRepository(this._dio);

  /// Submit a review
  Future<void> submitReview(ReviewRequest review) async {
    try {
      debugPrint('📝 [ReviewRepository] Submitting review...');
      debugPrint('   Job ID: ${review.jobId}');
      debugPrint('   Reviewee ID: ${review.revieweeId}');
      debugPrint('   Rating: ${review.rating}');

      final response = await _dio.post(
        ApiEndpoints.reviews,
        data: review.toJson(),
      );

      debugPrint('✅ [ReviewRepository] Review submitted: ${response.data}');
    } on DioException catch (e) {
      debugPrint('❌ [ReviewRepository] DioException: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Bad request';
        throw Exception(message);
      }

      rethrow;
    } catch (e) {
      debugPrint('❌ [ReviewRepository] Error: $e');
      rethrow;
    }
  }

  /// Get reviews for a specific job
  Future<List<Review>> getJobReviews(String jobId) async {
    try {
      debugPrint('🔍 [ReviewRepository] Fetching reviews for job: $jobId');

      final response = await _dio.get(
        ApiEndpoints.jobReviews(jobId),
      );

      final reviewsData = response.data['data']['reviews'] as List;
      final reviews = reviewsData
          .map((json) => Review.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [ReviewRepository] Found ${reviews.length} reviews');
      return reviews;
    } catch (e) {
      debugPrint('❌ [ReviewRepository] Error fetching job reviews: $e');
      rethrow;
    }
  }

  /// Get reviews for a specific user
  Future<List<Review>> getUserReviews(String userId) async {
    try {
      debugPrint('🔍 [ReviewRepository] Fetching reviews for user: $userId');

      final response = await _dio.get(
        ApiEndpoints.userReviews(userId),
      );

      final reviewsData = response.data['data']['reviews'] as List;
      final reviews = reviewsData
          .map((json) => Review.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [ReviewRepository] Found ${reviews.length} reviews');
      return reviews;
    } catch (e) {
      debugPrint('❌ [ReviewRepository] Error fetching user reviews: $e');
      rethrow;
    }
  }

  /// ✅ NEW: Check if current user has reviewed a specific reviewee for a job
  Future<bool> hasReviewed({
    required String jobId,
    required String revieweeId,
  }) async {
    try {
      debugPrint('🔍 [ReviewRepository] Checking review status...');
      debugPrint('   Job ID: $jobId');
      debugPrint('   Reviewee ID: $revieweeId');

      final response = await _dio.get(
        '/reviews/check/$jobId/$revieweeId',
      );

      final hasReviewed = response.data['hasReviewed'] as bool? ?? false;

      debugPrint('   Result: ${hasReviewed ? "Already reviewed ✅" : "Not reviewed yet ❌"}');

      return hasReviewed;
    } catch (e) {
      debugPrint('❌ [ReviewRepository] Error checking review: $e');
      // On error, assume not reviewed (allow user to try)
      return false;
    }
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ReviewRepository(dio);
});
