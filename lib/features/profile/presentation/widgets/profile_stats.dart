// Profile Stats
// =====================================================
// lib/features/profile/presentation/widgets/profile_stats.dart
// =====================================================
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ProfileStats extends StatelessWidget {
  final int productsPosted;
  final int activeProducts;
  final int totalViews;
  final double rating;

  const ProfileStats({
    super.key,
    required this.productsPosted,
    required this.activeProducts,
    required this.totalViews,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(context, 'Products', productsPosted.toString(), Icons.shopping_bag_outlined),
          _buildStat(context, 'Active', activeProducts.toString(), Icons.check_circle_outline),
          _buildStat(context, 'Views', totalViews.toString(), Icons.visibility_outlined),
          _buildStat(context, 'Rating', rating.toStringAsFixed(1), Icons.star_outline),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, IconData icon) {
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: primaryColor, size: 24),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textMutedLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
