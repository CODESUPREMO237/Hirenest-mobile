import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/product_model.dart';
import 'package:go_router/go_router.dart';

class SellerInfoCard extends StatelessWidget {
  final SellerModel seller;

  const SellerInfoCard({
    super.key,
    required this.seller,
  });

  @override
  Widget build(BuildContext context) {
    final String displayName = seller.name ?? 'Unknown Seller';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seller Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (seller.id.isNotEmpty)
                TextButton.icon(
                  onPressed: () => context.push('/profile/${seller.id}'),
                  icon: const Icon(Icons.arrow_forward_ios, size: 14),
                  label: const Text('View Profile'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: (seller.avatar != null && seller.avatar!.isNotEmpty)
                      ? Image.network(
                          seller.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, _) => _buildFallbackAvatar(context, displayName),
                        )
                      : _buildFallbackAvatar(context, displayName),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (seller.rating != null && seller.rating! > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            seller.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' (${seller.reviewCount ?? 0} reviews)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Text(
                          'New Seller',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(BuildContext context, String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}