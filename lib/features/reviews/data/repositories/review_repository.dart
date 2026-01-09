import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart'; // Ensure dioProvider is exported here
import '../models/review_model.dart';

// 1. Define Providers GLOBALLY (outside the class)
final reviewRepositoryProvider = Provider((ref) => ReviewRepository(ref));

final hasReviewedJobProvider = FutureProvider.family<bool, String>(
      (ref, jobId) async {
    final repository = ref.watch(reviewRepositoryProvider);
    return await repository.hasReviewedJob(jobId);
  },
);

class ReviewRepository {
  final Ref _ref;
  ReviewRepository(this._ref);

  // Helper to get dio instance easily
  // Assuming your dio provider is named 'dioProvider'
  get _dio => _ref.read(dioProvider);

  Future<bool> hasReviewedJob(String jobId) async {
    try {
      // Use the getter or _ref.read directly
      final response = await _dio.get('/reviews/check/$jobId');

      return response.data['hasReviewed'] ?? false;
    } catch (e) {
      print('❌ Error checking review status: $e');
      return false;
    }
  }

  Future<void> submitReview(ReviewRequest review) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.reviews,
        data: review.toJson(),
      );
      print('✅ Review submitted successfully: ${response.statusCode}');
    } catch (e) {
      print('❌ Error submitting review: $e');
      rethrow;
    }
  }

  Future<List<Review>> getUserReviews(String userId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.userReviews(userId),
      );

      final List<dynamic> data = response.data['data']['reviews'] ?? [];
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching user reviews: $e');
      rethrow;
    }
  }
}