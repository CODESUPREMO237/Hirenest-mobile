// lib/features/jobs/presentation/widgets/job_filter_sheet.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/jobs_provider.dart';

class JobFilterSheet extends StatefulWidget {
  final Function(JobFilters) onApply;
  const JobFilterSheet({super.key, required this.onApply});

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  String? _selectedCategory;
  String? _selectedJobType;
  bool? _remoteOnly;

  final List<String> _categories = ['Technology', 'Marketing', 'Sales', 'Design', 'Other'];
  final List<String> _jobTypes = ['full-time', 'part-time', 'contract', 'internship'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: AppSpacing.roundedFull,
                ),
              ),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Jobs', style: AppTextStyles.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMutedLight),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Category Chips
            Text('Category', style: AppTextStyles.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _categories.map((c) {
                final isSelected = _selectedCategory == c;
                return ChoiceChip(
                  label: Text(c),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = selected ? c : null);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.backgroundLight,
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedFull),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Job Type Chips
            Text('Job Type', style: AppTextStyles.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _jobTypes.map((t) {
                final isSelected = _selectedJobType == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedJobType = selected ? t : null);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: AppColors.backgroundLight,
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedFull),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Remote Only Toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderLight),
                borderRadius: AppSpacing.roundedMd,
              ),
              child: SwitchListTile(
                title: Text('Remote Only', style: AppTextStyles.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600) ?? const TextStyle()),
                subtitle: Text('Show only remote opportunities', style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight)),
                value: _remoteOnly ?? false,
                activeThumbColor: AppColors.primary,
                onChanged: (value) => setState(() => _remoteOnly = value),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                        _selectedJobType = null;
                        _remoteOnly = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                    ),
                    child: const Text('Reset', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(JobFilters(
                        category: _selectedCategory,
                        jobType: _selectedJobType,
                        remote: _remoteOnly,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                      elevation: 0,
                    ),
                    child: const Text('Apply Filters', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}