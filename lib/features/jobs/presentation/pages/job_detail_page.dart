// lib/features/jobs/presentation/pages/job_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

// Providers
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/jobs_provider.dart';

// Widgets & Models
import '../widgets/job_details_section.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs_repository.dart';

class JobDetailPage extends ConsumerWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final userAsync = ref.watch(currentUserProvider);
    final currentUser = userAsync.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Job Details', style: AppTextStyles.textTheme.titleLarge),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryLight),
          onPressed: () => context.canPop() ? context.pop() : context.go('/jobs'),
        ),
      ),
      body: jobAsync.when(
        data: (job) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(jobDetailProvider(jobId)),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyHeader(context, job),
                  _buildTitleSection(context, job),
                  if (job.salary != null && job.salary!.showSalary) _buildSalaryCard(job),

                  const SizedBox(height: AppSpacing.lg),

                  // Stats Card if owner
                  if (job.stats != null && currentUser?.id.toString() == job.postedBy.toString())
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: _buildStatsCard(job),
                    ),

                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    color: AppColors.surfaceLight,
                    child: JobDetailsSection(job: job),
                  ),
                  const SizedBox(height: 120), // Space for bottom buttons
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(child: Text('Error: $error', style: AppTextStyles.textTheme.bodyLarge?.copyWith(color: AppColors.error))),
      ),
      bottomNavigationBar: jobAsync.maybeWhen(
        data: (job) {
          final currentUserId = currentUser?.id.toString();
          final postedById = job.postedBy.toString();

          final isOwner = currentUserId != null && currentUserId == postedById;
          final isEmployer = currentUser?.role == 'employer';

          if (isOwner) {
            return _buildOwnerActions(context, ref, job);
          }

          if (isEmployer) {
            return const SizedBox.shrink();
          }

          return _buildApplyButton(context, job);
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  // --- OWNER ACTIONS (VIEW, EDIT, DELETE) ---

  Widget _buildOwnerActions(BuildContext context, WidgetRef ref, JobModel job) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: AppSpacing.bottomNavShadow,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.push('/jobs/${job.id}/applicants', extra: job.title),
              icon: const Icon(Icons.people_alt_outlined, color: AppColors.white),
              label: Text('View Applicants (${job.stats?.applications ?? 0})', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                elevation: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/jobs/${job.id}/edit'),
                    icon: const Icon(Icons.edit, color: AppColors.textPrimaryLight),
                    label: const Text('Edit', style: TextStyle(color: AppColors.textPrimaryLight)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref, job),
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, JobModel job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: Text('Delete Job Posting?', style: AppTextStyles.textTheme.titleLarge),
        content: Text('This action cannot be undone. All applications for this job will also be inaccessible.', style: AppTextStyles.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMutedLight))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
            ),
            child: const Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(jobsRepositoryProvider).deleteJob(job.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job deleted successfully'), backgroundColor: AppColors.success));
          context.go('/jobs');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting job: $e'), backgroundColor: AppColors.error));
        }
      }
    }
  }

  Widget _buildStatsCard(JobModel job) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _buildStatRow('👁️ Total Views', '${job.stats?.views ?? 0}'),
          const Divider(color: AppColors.borderLight, height: AppSpacing.lg),
          _buildStatRow('👤 Unique Views', '${job.stats?.uniqueViews ?? 0}'),
          const Divider(color: AppColors.borderLight, height: AppSpacing.lg),
          _buildStatRow('📝 Applications', '${job.stats?.applications ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
        Text(value, style: AppTextStyles.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }

  Widget _buildCompanyHeader(BuildContext context, JobModel job) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.xl, left: AppSpacing.xl, right: AppSpacing.xl),
      child: Column(
        children: [
          if (job.company.logo != null)
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: AppSpacing.elevatedShadow,
              ),
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Image.network(job.company.logo!, width: 72, height: 72, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: AppSpacing.elevatedShadow,
              ),
              child: Center(
                child: Text(
                  job.company.name.isNotEmpty ? job.company.name[0].toUpperCase() : '?',
                  style: AppTextStyles.textTheme.headlineMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            job.company.name, 
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.white, 
              fontWeight: FontWeight.bold
            )
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, JobModel job) {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.title, style: AppTextStyles.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _buildJobChip(job.jobType, AppColors.primary, Icons.work_outline),
              _buildJobChip(job.location.type, AppColors.success, Icons.location_on_outlined),
              _buildJobChip(job.experienceLevel, AppColors.warning, Icons.school_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSalaryCard(JobModel job) {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments, color: AppColors.success),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Salary Range', style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.successDark)),
                const SizedBox(height: 2),
                Text(
                  '${job.salary!.min} - ${job.salary!.max} ${job.salary!.currency}',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.successDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context, JobModel job) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: AppSpacing.bottomNavShadow,
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: job.isApplied ? null : () => context.push('/jobs/${job.id}/apply'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: job.isApplied ? AppColors.borderLight : AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
            elevation: 0,
          ),
          child: Text(
            job.isApplied ? 'Already Applied' : 'Apply Now',
            style: AppTextStyles.textTheme.titleMedium?.copyWith(
              color: job.isApplied ? AppColors.textMutedLight : AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}