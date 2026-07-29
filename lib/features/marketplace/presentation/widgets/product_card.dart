import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/product_model.dart';
import 'package:intl/intl.dart';

extension ProductImageExtension on ProductModel {
  String get primaryImageFullUrl {
    if (images.isEmpty) return '';
    final primary = images.firstWhere((img) => img.isPrimary, orElse: () => images[0]);
    return primary.url;
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  String _getConditionText(String condition) {
    switch (condition.toLowerCase()) {
      case 'new': return 'New';
      case 'like_new': return 'Like New';
      case 'good': return 'Good';
      case 'fair': return 'Fair';
      case 'poor': return 'Poor';
      default: return condition;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new': return AppColors.success;
      case 'like_new': return AppColors.primary;
      case 'good': return AppColors.accent;
      case 'fair': return AppColors.warning;
      case 'poor': return AppColors.error;
      default: return AppColors.textMutedLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSold = product.status.toLowerCase() == 'sold';
    final Color statusColor = isSold ? AppColors.error : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.roundedLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Section
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1, // Square image
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
                      child: Image.network(
                        product.primaryImageFullUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textMutedLight.withValues(alpha: 0.5)
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Status Badge (Sold/Available)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Text(
                        product.status.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  
                  // Condition Badge
                  Positioned(
                    bottom: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _getConditionColor(product.condition).withValues(alpha: 0.9),
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Text(
                        _getConditionText(product.condition),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Details Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xs),
                      
                      // Price & Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              NumberFormat.currency(
                                symbol: '${product.price.currency} ',
                                decimalDigits: 0,
                              ).format(product.price.amount),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isSold 
                                    ? AppColors.textMutedLight 
                                    : Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: isSold ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}