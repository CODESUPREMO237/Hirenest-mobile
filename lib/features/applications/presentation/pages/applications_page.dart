// lib/features/applications/presentation/pages/applications_page.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reviews/presentation/widgets/rating_dialog.dart';
import '../../../reviews/presentation/providers/reviews_provider.dart';
import '../../data/models/application_model.dart';
import '../providers/applications_provider.dart';
import '../widgets/application_card.dart';

class ApplicationsPage extends ConsumerWidget {
  const ApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);
    final applicationsAsync = ref.watch(myApplicationsProvider);
    final statsAsync = ref.watch(applicationStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: roleAsync.when(
          data: (role) => Text(
            role == 'employer' ? 'Applications Received' : 'My Applications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
          ),
          loading: () => const Text('Applications'),
          error: (err, stack) => const Text('Applications'),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats Summary Section
          statsAsync.when(
            data: (stats) => Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppSpacing.roundedLg,
                boxShadow: AppSpacing.cardShadow,
              ),
              child: roleAsync.when(
                data: (role) => _buildStatsRow(context, stats, role),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),
            loading: () => const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          // Applications List Section
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              onRefresh: () async {
                ref.invalidate(myApplicationsProvider);
                ref.invalidate(applicationStatsProvider);
                await ref.read(myApplicationsProvider.future);
              },
              child: applicationsAsync.when(
                data: (applications) {
                  if (applications.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: roleAsync.when(
                            data: (role) => _buildEmptyState(context, role),
                            loading: () => const CircularProgressIndicator(color: AppColors.primary),
                            error: (err, stack) => const Text('Error loading role'),
                          ),
                        ),
                      ],
                    );
                  }

                  final isEmployer = roleAsync.whenOrNull(
                    data: (role) => role == 'employer',
                  ) ?? false;

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      final application = applications[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Column(
                          children: [
                            ApplicationCard(
                              application: application,
                              isEmployerView: isEmployer,
                            ),
                            if (!isEmployer && _canRateEmployer(application))
                              _buildRatingButton(context, ref, application),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                        child: Text(
                          'Error: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () => ref.invalidate(myApplicationsProvider),
                        child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canRateEmployer(ApplicationModel application) {
    final status = application.status.toLowerCase();
    return status == 'rejected' || status == 'completed' || status == 'accepted';
  }

  Widget _buildRatingButton(BuildContext context, WidgetRef ref, ApplicationModel application) {
    String employerId = '';
    final jobDetails = application.jobDetails;

    if (jobDetails != null) {
      employerId = jobDetails.postedBy;
    }

    if (employerId.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasReviewedAsync = ref.watch(
      hasReviewedProvider(ReviewCheckParams(jobId: application.job, revieweeId: employerId)),
    );

    return hasReviewedAsync.when(
      data: (hasReviewed) {
        if (hasReviewed) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: null,
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Already Reviewed'),
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: AppColors.success.withValues(alpha: 0.1),
                  disabledForegroundColor: AppColors.success.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => _showRatingDialog(context, ref, application),
              icon: const Icon(Icons.star_outline, size: 18),
              label: const Text('Rate Employer'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                foregroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
              ),
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: null,
            icon: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            label: const Text('Checking...'),
          ),
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: () => _showRatingDialog(context, ref, application),
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('Rate Employer'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              foregroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref, ApplicationModel application) {
    String employerId = '';
    String employerName = 'Employer';
    String jobId = application.job;
    final jobDetails = application.jobDetails;

    if (jobDetails != null) {
      employerId = jobDetails.postedBy;
      if (jobDetails.postedByDetails != null) {
        final employer = jobDetails.postedByDetails!;
        final profile = employer.profile;
        if (profile != null) {
          employerName = profile.displayName ?? '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
          if (employerName.isEmpty || employerName == ' ') employerName = employer.email.split('@')[0];
        } else {
          employerName = employer.email.split('@')[0];
        }
      } else {
        employerName = jobDetails.company.name;
      }
    }

    if (jobId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot find job information. Please try again.'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    if (employerId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Job details not fully loaded. Pull to refresh.'),
            backgroundColor: AppColors.warning,
            action: SnackBarAction(
              label: 'Refresh',
              textColor: AppColors.white,
              onPressed: () => ref.invalidate(myApplicationsProvider),
            ),
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => RatingDialog(jobId: jobId, revieweeId: employerId, revieweeName: employerName),
    ).then((success) {
      if (success == true) {
        ref.invalidate(myApplicationsProvider);
        ref.invalidate(hasReviewedProvider(ReviewCheckParams(jobId: jobId, revieweeId: employerId)));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: AppColors.success),
          );
        }
      }
    });
  }

  Widget _buildStatsRow(BuildContext context, Map<String, int> stats, String role) {
    int getStatValue(String key) => stats[key] ?? 0;
    if (role == 'employer') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem('Total', getStatValue('total'), AppColors.primary),
          _StatItem('Pending', getStatValue('pending'), AppColors.warning),
          _StatItem('Reviewing', getStatValue('reviewing'), AppColors.accent),
          _StatItem('Interviews', getStatValue('interviewing'), AppColors.success),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem('Total', getStatValue('total'), AppColors.primary),
          _StatItem('Pending', getStatValue('pending'), AppColors.warning),
          _StatItem('Shortlisted', getStatValue('shortlisted'), AppColors.success),
          _StatItem('Rejected', getStatValue('rejected'), AppColors.error),
        ],
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, String role) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            role == 'employer' ? Icons.people_outline : Icons.description_outlined,
            size: 64,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          role == 'employer' ? 'No applications received' : 'No applications yet',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Text(
            role == 'employer'
                ? 'Post jobs to start receiving applications from top talent.'
                : 'Start exploring and applying to jobs to see them here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMutedLight,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryLight,
              ),
        ),
      ],
    );
  }
}
