// Job Card
// ============================================================================
// job_card.dart
// lib/features/jobs/presentation/widgets/job_card.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/job_model.dart';
import '../../../../core/theme/app_colors.dart';

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with company logo and name
              Row(
                children: [
                  if (job.company.logo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          job.company.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.company.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

              const SizedBox(height: 12),

              // Job details chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '${NumberFormat.compact().format(job.salary!.min)} - ${NumberFormat.compact().format(job.salary!.max)} ${job.salary!.currency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Footer with time and applicants
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeAgo(job.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (job.applicantsCount != null) ...[
                    const Spacer(),
                    Icon(Icons.people_outline, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${job.applicantsCount} applicants',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
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
        return AppColors.fullTime;
      case 'part-time':
        return AppColors.partTime;
      case 'contract':
        return AppColors.contract;
      case 'internship':
        return AppColors.internship;
      case 'freelance':
        return AppColors.freelance;
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