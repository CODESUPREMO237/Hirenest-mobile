// Updated Employer Dashboard with Real Stats
// lib/features/home/presentation/pages/employer_dashboard_page.dart

import 'package:flutter/material.dart';
import '../../../../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../../jobs/data/models/job_model.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../talent/presentation/providers/talent_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/logger.dart';

class EmployerDashboardPage extends ConsumerWidget {
  const EmployerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myJobsAsync = ref.watch(myJobsProvider);
    final analyticsAsync = ref.watch(userAnalyticsProvider);
    final talentAsync = ref.watch(talentListProvider);
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myJobsProvider);
          ref.invalidate(userAnalyticsProvider);
          ref.invalidate(talentListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Employer Dashboard',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
                  onPressed: () {
                    context.push('/profile/notifications');
                  },
                ),
              ],
            ),

            // Quick Access Cards - Company & Analytics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.business,
                        title: 'Company',
                        subtitle: 'Manage Profile',
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        onTap: () => context.push('/company/dashboard'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        subtitle: 'View Insights',
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent,
                            AppColors.accent.withValues(alpha: 0.8),
                          ],
                        ),
                        onTap: () => context.push('/analytics'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Stats - Using Analytics Data
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: analyticsAsync.when(
                  data: (analytics) {
                    final activeJobs = analytics['activeJobs'] ?? 0;
                    final totalApplications = analytics['totalApplications'] ?? 0;
                    final filledJobs = analytics['jobsByStatus']
                        ?.firstWhere(
                          (s) => s['_id'] == 'filled',
                      orElse: () => {'count': 0},
                    )['count'] ?? 0;

                    // Calculate total views from all jobs
                    final totalViews = analytics['totalViews'] ?? 0;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.work_outline,
                                title: 'Active Jobs',
                                value: '$activeJobs',
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.people_outline,
                                title: 'Applications',
                                value: '$totalApplications',
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle_outline,
                                title: 'Filled',
                                value: '$filledJobs',
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.trending_up,
                                title: 'Views',
                                value: '$totalViews',
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.work_outline,
                              title: 'Active Jobs',
                              value: '...',
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.people_outline,
                              title: 'Applications',
                              value: '...',
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_outline,
                              title: 'Filled',
                              value: '...',
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.trending_up,
                              title: 'Views',
                              value: '...',
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: CustomErrorWidget(
                        error: error,
                        onRetry: () {
                          AppLogger.info('Retrying employer dashboard stats');
                          ref.invalidate(userAnalyticsProvider);
                          ref.invalidate(myJobsProvider);
                          ref.invalidate(talentListProvider);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add_circle_outline,
                            title: 'Post New Job',
                            color: AppColors.success,
                            onTap: () => context.push('/jobs/create'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.list_alt,
                            title: 'Manage Jobs',
                            color: primaryColor,
                            onTap: () => context.push('/jobs'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Discover Talent Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discover Talent',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: talentAsync.when(
                  data: (talents) {
                    if (talents.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, size: 48, color: AppColors.textMutedLight),
                              const SizedBox(height: AppSpacing.sm),
                              Text('No job seekers yet', style: textTheme.bodyMedium?.copyWith(color: AppColors.textMutedLight)),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: talents.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: _TalentCard(
                            user: talents[index],
                            onTap: () => context.push('/talent/${talents[index].id}'),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: CustomErrorWidget(
                        error: error,
                        onRetry: () {
                          AppLogger.info('Retrying employer dashboard talent');
                          ref.invalidate(userAnalyticsProvider);
                          ref.invalidate(myJobsProvider);
                          ref.invalidate(talentListProvider);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Recent Jobs Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Posted Jobs',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/jobs'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ),

            // Jobs List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: myJobsAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.work_outline,
                                size: 80,
                                color: AppColors.textMutedLight,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'No jobs posted yet',
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Post your first job to start receiving applications',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMutedLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/jobs/create'),
                                icon: const Icon(Icons.add),
                                label: const Text('Post Your First Job'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xl,
                                    vertical: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppSpacing.roundedMd,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Show up to 5 recent jobs
                  final displayJobs = jobs.take(5).toList();

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final job = displayJobs[index];
                        return _JobCard(job: job);
                      },
                      childCount: displayJobs.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: CustomErrorWidget(
                      error: error,
                      onRetry: () {
                        AppLogger.info('Retrying employer dashboard jobs');
                        ref.invalidate(userAnalyticsProvider);
                        ref.invalidate(myJobsProvider);
                        ref.invalidate(talentListProvider);
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'employer_dashboard_fab',
        backgroundColor: primaryColor,
        foregroundColor: AppColors.white,
        onPressed: () => context.push('/jobs/create'),
        icon: const Icon(Icons.add),
        label: const Text('Post Job'),
      ),
    );
  }
}

// Quick Access Card Widget
class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.white.withValues(alpha: 0.8),
                      size: 20,
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMutedLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, color: AppColors.white, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/jobs/${job.id}'),
          borderRadius: AppSpacing.roundedLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    _StatusBadge(status: job.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: AppColors.textMutedLight),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${job.applicantsCount} applicants',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const Icon(Icons.visibility_outlined, size: 16, color: AppColors.textMutedLight),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${job.views} views',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Posted ${_getTimeAgo(job.createdAt)}',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = AppColors.success;
        text = 'Active';
        break;
      case 'paused':
        color = AppColors.warning;
        text = 'Paused';
        break;
      case 'closed':
        color = AppColors.error;
        text = 'Closed';
        break;
      case 'filled':
        color = Theme.of(context).primaryColor;
        text = 'Filled';
        break;
      default:
        color = AppColors.textMutedLight;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TalentCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _TalentCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final skills = user.jobSeekerProfile?.skills?.take(3).toList() ?? [];
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.backgroundLight,
                  backgroundImage: user.profile?.avatar != null
                      ? NetworkImage(user.profile!.avatar!)
                      : null,
                  child: user.profile?.avatar == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  user.displayName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (user.profile?.headline != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    user.profile!.headline!,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                if (skills.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    alignment: WrapAlignment.center,
                    children: skills
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Text(
                                s.name ?? '',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}