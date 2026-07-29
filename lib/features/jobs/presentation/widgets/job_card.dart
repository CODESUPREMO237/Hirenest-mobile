// lib/features/jobs/presentation/widgets/job_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/job_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onTap;
  final Widget? trailing;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedMd,
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with company logo and name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (job.company.logo != null)
                      ClipRRect(
                        borderRadius: AppSpacing.roundedSm,
                        child: Image.network(
                          job.company.logo!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Center(
                          child: Text(
                            job.company.name.isNotEmpty ? job.company.name[0].toUpperCase() : '?',
                            style: AppTextStyles.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: AppTextStyles.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job.company.name,
                            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                
                const SizedBox(height: AppSpacing.md),

                // Job details chips
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _buildChip(
                      context,
                      Icons.work_outline,
                      job.jobType,
                      _getJobTypeColor(job.jobType),
                    ),
                    _buildChip(
                      context,
                      Icons.location_on_outlined,
                      job.location.type,
                      AppColors.success,
                    ),
                    _buildChip(
                      context,
                      Icons.school_outlined,
                      job.experienceLevel,
                      AppColors.warning,
                    ),
                  ],
                ),

                if (job.salary != null && job.salary!.showSalary) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 18, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '${NumberFormat.compact().format(job.salary!.min)} - ${NumberFormat.compact().format(job.salary!.max)} ${job.salary!.currency}',
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.successDark,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: AppSpacing.md),

                // Footer with time and applicants
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.textMutedLight),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(job.createdAt),
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 14, color: AppColors.textMutedLight),
                        const SizedBox(width: 4),
                        Text(
                          '${job.applicantsCount} applicants',
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getJobTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'full-time':
        return AppColors.primary;
      case 'part-time':
        return AppColors.accent;
      case 'contract':
        return AppColors.warning;
      case 'internship':
        return AppColors.success;
      case 'freelance':
        return AppColors.primaryDark;
      default:
        return AppColors.primary;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}