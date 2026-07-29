import 'package:flutter/foundation.dart';
// lib/features/reviews/presentation/providers/reviews_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/review_repository.dart';

/// ✅ FIXED: Check if current user has reviewed a specific reviewee for a job
final hasReviewedProvider = FutureProvider.family<bool, ReviewCheckParams>(
      (ref, params) async {
    try {
      final repository = ref.read(reviewRepositoryProvider);

      debugPrint('🔍 [hasReviewedProvider] Checking for existing review');
      debugPrint('   Job ID: ${params.jobId}');
      debugPrint('   Reviewee ID: ${params.revieweeId}');

      // ✅ Use the new hasReviewed method that calls the correct endpoint
      final hasReviewed = await repository.hasReviewed(
        jobId: params.jobId,
        revieweeId: params.revieweeId,
      );

      debugPrint('   Result: ${hasReviewed ? "Already reviewed ✅" : "Not reviewed yet ❌"}');

      return hasReviewed;
    } catch (e) {
      debugPrint('❌ [hasReviewedProvider] Error checking review: $e');
      // On error, assume not reviewed (allow user to try)
      return false;
    }
  },
);

/// Parameters for review check
class ReviewCheckParams {
  final String jobId;
  final String revieweeId;

  const ReviewCheckParams({
    required this.jobId,
    required this.revieweeId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ReviewCheckParams &&
              runtimeType == other.runtimeType &&
              jobId == other.jobId &&
              revieweeId == other.revieweeId;

  @override
  int get hashCode => jobId.hashCode ^ revieweeId.hashCode;
}
