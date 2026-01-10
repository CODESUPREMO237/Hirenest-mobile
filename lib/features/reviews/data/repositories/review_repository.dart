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
      print('📝 [ReviewRepository] Submitting review...');
      print('   Job ID: ${review.jobId}');
      print('   Reviewee ID: ${review.revieweeId}');
      print('   Rating: ${review.rating}');

      final response = await _dio.post(
        ApiEndpoints.reviews,
        data: review.toJson(),
      );

      print('✅ [ReviewRepository] Review submitted: ${response.data}');
    } on DioException catch (e) {
      print('❌ [ReviewRepository] DioException: ${e.response?.data}');

      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? 'Bad request';
        throw Exception(message);
      }

      rethrow;
    } catch (e) {
      print('❌ [ReviewRepository] Error: $e');
      rethrow;
    }
  }

  /// Get reviews for a specific job
  Future<List<Review>> getJobReviews(String jobId) async {
    try {
      print('🔍 [ReviewRepository] Fetching reviews for job: $jobId');

      final response = await _dio.get(
        ApiEndpoints.jobReviews(jobId),
      );

      final reviewsData = response.data['data']['reviews'] as List;
      final reviews = reviewsData
          .map((json) => Review.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [ReviewRepository] Found ${reviews.length} reviews');
      return reviews;
    } catch (e) {
      print('❌ [ReviewRepository] Error fetching job reviews: $e');
      rethrow;
    }
  }

  /// Get reviews for a specific user
  Future<List<Review>> getUserReviews(String userId) async {
    try {
      print('🔍 [ReviewRepository] Fetching reviews for user: $userId');

      final response = await _dio.get(
        ApiEndpoints.userReviews(userId),
      );

      final reviewsData = response.data['data']['reviews'] as List;
      final reviews = reviewsData
          .map((json) => Review.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ [ReviewRepository] Found ${reviews.length} reviews');
      return reviews;
    } catch (e) {
      print('❌ [ReviewRepository] Error fetching user reviews: $e');
      rethrow;
    }
  }

  /// ✅ NEW: Check if current user has reviewed a specific reviewee for a job
  Future<bool> hasReviewed({
    required String jobId,
    required String revieweeId,
  }) async {
    try {
      print('🔍 [ReviewRepository] Checking review status...');
      print('   Job ID: $jobId');
      print('   Reviewee ID: $revieweeId');

      final response = await _dio.get(
        '/reviews/check/$jobId/$revieweeId',
      );

      final hasReviewed = response.data['hasReviewed'] as bool? ?? false;

      print('   Result: ${hasReviewed ? "Already reviewed ✅" : "Not reviewed yet ❌"}');

      return hasReviewed;
    } catch (e) {
      print('❌ [ReviewRepository] Error checking review: $e');
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