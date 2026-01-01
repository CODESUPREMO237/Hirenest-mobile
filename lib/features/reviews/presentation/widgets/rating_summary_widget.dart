import 'package:flutter/material.dart';

class RatingSummaryWidget extends StatelessWidget {
  final double rating;
  final int count;
  final double size;

  const RatingSummaryWidget({
    super.key,
    required this.rating,
    required this.count,
    this.size = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Star Icon
        Icon(
          Icons.star_rounded,
          color: Colors.amber.shade700,
          size: size,
        ),
        const SizedBox(width: 4),
        // Average Rating Text
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 4),
        // Count Text
        Text(
          '($count ${count == 1 ? "review" : "reviews"})',
          style: TextStyle(
            fontSize: size * 0.8,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}