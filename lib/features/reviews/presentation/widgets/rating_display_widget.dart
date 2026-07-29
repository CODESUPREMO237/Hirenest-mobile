// ============================================================================
// rating_display_widget.dart
// lib/features/reviews/presentation/widgets/rating_display_widget.dart
// ============================================================================
// This widget DISPLAYS ratings (read-only)
// Different from RatingSummaryWidget which is for SUBMITTING reviews

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
    final textTheme = Theme.of(context).textTheme;

    // Handle null or zero ratings
    if (rating == null || rating == 0) {
      return Text(
        'No ratings yet',
        style: textTheme.bodySmall?.copyWith(
          color: color ?? AppColors.textMutedLight,
          fontSize: size * 0.7,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.star_rounded,
          color: color ?? AppColors.warning,
          size: size,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating!.toStringAsFixed(1),
          style: textTheme.labelLarge?.copyWith(
            color: color ?? AppColors.textPrimaryLight,
            fontSize: size * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showCount && count != null && count! > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '($count)',
            style: textTheme.bodySmall?.copyWith(
              color: (color ?? AppColors.textMutedLight).withValues(alpha: 0.8),
              fontSize: size * 0.7,
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
    this.activeColor = AppColors.warning,
    this.inactiveColor = AppColors.borderLight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return Icon(Icons.star_rounded, color: activeColor, size: size);
        } else if (index < rating.ceil() && rating % 1 != 0) {
          // Half star
          return Icon(Icons.star_half_rounded, color: activeColor, size: size);
        } else {
          // Empty star
          return Icon(Icons.star_outline_rounded, color: inactiveColor, size: size);
        }
      }),
    );
  }
}