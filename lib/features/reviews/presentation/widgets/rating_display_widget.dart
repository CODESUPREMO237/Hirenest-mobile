// ============================================================================
// rating_display_widget.dart - NEW FILE
// lib/features/reviews/presentation/widgets/rating_display_widget.dart
// ============================================================================
// This widget DISPLAYS ratings (read-only)
// Different from RatingSummaryWidget which is for SUBMITTING reviews

import 'package:flutter/material.dart';

class RatingDisplayWidget extends StatelessWidget {
  final double? rating;
  final int? count;
  final double size;
  final Color? color;
  final bool showCount;

  const RatingDisplayWidget({
    super.key,
    required this.rating,
    this.count,
    this.size = 20,
    this.color,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    // Handle null or zero ratings
    if (rating == null || rating == 0) {
      return Text(
        'No ratings yet',
        style: TextStyle(
          color: color ?? Colors.grey,
          fontSize: size * 0.7,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: color ?? Colors.amber,
          size: size,
        ),
        const SizedBox(width: 6),
        Text(
          rating!.toStringAsFixed(1),
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: size * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showCount && count != null && count! > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($count ${count == 1 ? 'review' : 'reviews'})',
            style: TextStyle(
              color: (color ?? Colors.white).withOpacity(0.9),
              fontSize: size * 0.65,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// Alternative: Star Rating Bar (shows 5 stars)
// ============================================================================
class StarRatingBar extends StatelessWidget {
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingBar({
    super.key,
    required this.rating,
    this.size = 20,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return Icon(Icons.star, color: activeColor, size: size);
        } else if (index < rating.ceil() && rating % 1 != 0) {
          // Half star
          return Icon(Icons.star_half, color: activeColor, size: size);
        } else {
          // Empty star
          return Icon(Icons.star_border, color: inactiveColor, size: size);
        }
      }),
    );
  }
}