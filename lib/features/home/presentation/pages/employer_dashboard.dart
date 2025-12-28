// Updated Employer Dashboard with Real Stats
// lib/features/home/presentation/pages/employer_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../../jobs/data/models/job_model.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';

class EmployerDashboardPage extends ConsumerWidget {
  const EmployerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myJobsAsync = ref.watch(myJobsProvider);
    final analyticsAsync = ref.watch(userAnalyticsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myJobsProvider);
          ref.invalidate(userAnalyticsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Employer Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    context.push('/profile/notifications');
                  },
                ),
              ],
            ),

            // Quick Access Cards - Company & Analytics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.business,
                        title: 'Company',
                        subtitle: 'Manage Profile',
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade600,
                            Colors.blue.shade400,
                          ],
                        ),
                        onTap: () => context.push('/company/dashboard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        subtitle: 'View Insights',
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade600,
                            Colors.purple.shade400,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.people_outline,
                                title: 'Applications',
                                value: '$totalApplications',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle_outline,
                                title: 'Filled',
                                value: '$filledJobs',
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.trending_up,
                                title: 'Views',
                                value: '$totalViews',
                                color: Colors.orange,
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
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.people_outline,
                              title: 'Applications',
                              value: '...',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_outline,
                              title: 'Filled',
                              value: '...',
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.trending_up,
                              title: 'Views',
                              value: '...',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text('Error loading stats: $error'),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => ref.invalidate(userAnalyticsProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add_circle_outline,
                            title: 'Post New Job',
                            color: Colors.green,
                            onTap: () => context.push('/jobs/create'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.list_alt,
                            title: 'Manage Jobs',
                            color: Colors.blue,
                            onTap: () => context.push('/jobs'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent Jobs Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Posted Jobs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: myJobsAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No jobs posted yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Post your first job to start receiving applications',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/jobs/create'),
                                icon: const Icon(Icons.add),
                                label: const Text('Post Your First Job'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
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
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading jobs: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(myJobsProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
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
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white.withOpacity(0.8),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/jobs/${job.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StatusBadge(status: job.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${job.applicantsCount ?? 0} applicants',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${job.views ?? 0} views',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Posted ${_getTimeAgo(job.createdAt)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
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
        color = Colors.green;
        text = 'Active';
        break;
      case 'paused':
        color = Colors.orange;
        text = 'Paused';
        break;
      case 'closed':
        color = Colors.red;
        text = 'Closed';
        break;
      case 'filled':
        color = Colors.blue;
        text = 'Filled';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}