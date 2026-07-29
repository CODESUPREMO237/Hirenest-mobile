import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onSelected,
  });

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics': return Icons.devices;
      case 'fashion': return Icons.checkroom;
      case 'home': return Icons.weekend;
      case 'sports': return Icons.sports_basketball;
      case 'books': return Icons.menu_book;
      case 'toys': return Icons.toys;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            // 'All' chip
            final isSelected = selectedCategory == null;
            return _buildChip(
              context,
              label: 'All',
              icon: Icons.grid_view,
              isSelected: isSelected,
              onTap: () => onSelected(null),
              isDark: isDark,
            );
          }

          final category = categories[index - 1];
          final isSelected = selectedCategory == category;
          return _buildChip(
            context,
            label: category,
            icon: _getCategoryIcon(category),
            isSelected: isSelected,
            onTap: () => onSelected(category),
            isDark: isDark,
          );
        },
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedFull,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? primaryColor 
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: AppSpacing.roundedFull,
            border: Border.all(
              color: isSelected 
                  ? primaryColor 
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected 
                    ? AppColors.white 
                    : (isDark ? AppColors.textMutedLight : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected 
                      ? AppColors.white 
                      : (isDark ? AppColors.textPrimaryLight : AppColors.textPrimaryLight),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
