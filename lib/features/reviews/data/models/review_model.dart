// lib/features/reviews/data/models/review_model.dart

/// Request model for submitting a review
class ReviewRequest {
  final String jobId;
  final String revieweeId;
  final double rating;
  final String comment;

  ReviewRequest({
    required this.jobId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
    'jobId': jobId,
    'revieweeId': revieweeId,
    'rating': rating,
    'comment': comment.trim(),
  };
}

/// Response model for receiving review data
class Review {
  final String id;
  final String jobId;
  final String reviewerId;
  final String revieweeId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ??
          (json['job'] is String ? json['job'] : json['job']?['_id'] ?? ''),
      reviewerId: json['reviewerId']?.toString() ??
          (json['reviewer'] is String ? json['reviewer'] : json['reviewer']?['_id'] ?? ''),
      revieweeId: json['revieweeId']?.toString() ??
          (json['reviewee'] is String ? json['reviewee'] : json['reviewee']?['_id'] ?? ''),
      rating: (json['rating'] is int)
          ? (json['rating'] as int).toDouble()
          : (json['rating'] as double? ?? 0.0),
      comment: json['comment']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'jobId': jobId,
    'reviewerId': reviewerId,
    'revieweeId': revieweeId,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// User rating summary (for displaying aggregate ratings)
class UserRatingSummary {
  final double averageRating;
  final int totalReviews;

  UserRatingSummary({
    required this.averageRating,
    required this.totalReviews,
  });

  factory UserRatingSummary.fromJson(Map<String, dynamic> json) {
    return UserRatingSummary(
      averageRating: (json['ratingsAverage'] is int)
          ? (json['ratingsAverage'] as int).toDouble()
          : (json['ratingsAverage'] as double? ?? 0.0),
      totalReviews: json['ratingsQuantity'] as int? ?? 0,
    );
  }

  bool get hasReviews => totalReviews > 0;
}