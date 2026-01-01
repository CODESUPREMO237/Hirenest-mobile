// lib/features/reviews/data/repositories/review_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/review_model.dart';

final reviewRepositoryProvider = Provider((ref) => ReviewRepository(ref));

class ReviewRepository {
  final Ref _ref;
  ReviewRepository(this._ref);

  /// Submit a review for a user after a job interaction
  Future<void> submitReview(ReviewRequest review) async {
    try {
      // ✅ FIX: Use dioProvider instead of dioClientProvider
      final dio = _ref.read(dioProvider);

      final response = await dio.post(
        ApiEndpoints.reviews,
        data: review.toJson(),
      );

      // Optional: Log success
      print('✅ Review submitted successfully: ${response.statusCode}');

    } catch (e) {
      print('❌ Error submitting review: $e');
      rethrow;
    }
  }

  /// Get reviews for a specific user (optional for future use)
  Future<List<Review>> getUserReviews(String userId) async {
    try {
      final dio = _ref.read(dioProvider);

      final response = await dio.get(
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