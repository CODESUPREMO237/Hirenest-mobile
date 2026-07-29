import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../applications/data/models/application_model.dart';
import '../../../applications/data/repositories/applications_repository.dart';
import '../../../../core/network/dio_client.dart';
import '../../../reviews/presentation/widgets/rating_dialog.dart';
import '../../../reviews/presentation/providers/reviews_provider.dart';

class JobApplicantsPage extends ConsumerStatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicantsPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  ConsumerState<JobApplicantsPage> createState() => _JobApplicantsPageState();
}

class _JobApplicantsPageState extends ConsumerState<JobApplicantsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicantsAsync = ref.watch(jobApplicantsProvider(widget.jobId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applicants'),
            Text(
              widget.jobTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMutedLight,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Shortlisted'),
            Tab(text: 'Reviewed'),
          ],
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedFilter = 'all';
                  break;
                case 1:
                  _selectedFilter = 'pending';
                  break;
                case 2:
                  _selectedFilter = 'shortlisted';
                  break;
                case 3:
                  _selectedFilter = 'reviewed';
                  break;
              }
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textPrimaryLight),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: applicantsAsync.when(
        data: (applicants) {
          final filteredApplicants = _filterApplicants(applicants);

          if (filteredApplicants.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(jobApplicantsProvider(widget.jobId));
              await ref.read(jobApplicantsProvider(widget.jobId).future);
            },
            child: Column(
              children: [
                _buildStatsSummary(applicants),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filteredApplicants.length,
                    itemBuilder: (context, index) {
                      return _ApplicantCard(
                        application: filteredApplicants[index],
                        jobId: widget.jobId,
                        onTap: () => _viewApplicantDetails(
                          context,
                          filteredApplicants[index],
                        ),
                        onShortlist: () => _shortlistApplicant(
                          filteredApplicants[index],
                        ),
                        onReject: () => _rejectApplicant(
                          filteredApplicants[index],
                        ),
                        onRate: () => _rateApplicant(
                          context,
                          filteredApplicants[index],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading applicants: $error', style: const TextStyle(color: AppColors.textSecondaryLight)),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(jobApplicantsProvider(widget.jobId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ApplicationModel> _filterApplicants(List<ApplicationModel> applicants) {
    if (_selectedFilter == 'all') return applicants;
    if (_selectedFilter == 'reviewed') {
      return applicants
          .where((app) => app.status == 'accepted' || app.status == 'rejected')
          .toList();
    }
    return applicants.where((app) => app.status == _selectedFilter).toList();
  }

  void _rateApplicant(BuildContext context, ApplicationModel application) {
    final applicantId = application.applicantDetails?.id ?? application.applicant;

    String applicantName = 'Applicant';
    final profile = application.applicantDetails?.profile;
    if (profile != null) {
      applicantName = '${profile.firstName ?? ""} ${profile.lastName ?? ""}'.trim();
      if (applicantName.isEmpty) {
        applicantName = 'Applicant';
      }
    }

    if (applicantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit rating: Missing applicant information'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        jobId: widget.jobId,
        revieweeId: applicantId,
        revieweeName: applicantName,
      ),
    ).then((success) {
      if (success == true && mounted) {
        ref.invalidate(jobApplicantsProvider(widget.jobId));
        ref.invalidate(
          hasReviewedProvider(
            ReviewCheckParams(
              jobId: widget.jobId,
              revieweeId: applicantId,
            ),
          ),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rating submitted successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    });
  }

  Widget _buildStatsSummary(List<ApplicationModel> applicants) {
    final total = applicants.length;
    final pending = applicants.where((a) => a.status == 'pending').length;
    final shortlisted = applicants.where((a) => a.status == 'shortlisted').length;
    final reviewed = applicants.where((a) =>
    a.status == 'accepted' || a.status == 'rejected').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.people,
            label: 'Total',
            value: total.toString(),
            color: AppColors.primary,
          ),
          _StatItem(
            icon: Icons.schedule,
            label: 'Pending',
            value: pending.toString(),
            color: AppColors.warning,
          ),
          _StatItem(
            icon: Icons.star,
            label: 'Shortlisted',
            value: shortlisted.toString(),
            color: AppColors.accent,
          ),
          _StatItem(
            icon: Icons.check_circle,
            label: 'Reviewed',
            value: reviewed.toString(),
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 80, color: AppColors.textMutedLight),
          const SizedBox(height: AppSpacing.md),
          Text(
            _selectedFilter == 'all'
                ? 'No applicants yet'
                : 'No $_selectedFilter applicants',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Applications will appear here when candidates apply',
            style: TextStyle(color: AppColors.textMutedLight, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Applicants',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.sort, color: AppColors.textSecondaryLight),
              title: const Text('Sort by: Most Recent'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMutedLight),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sorting by most recent')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: AppColors.textSecondaryLight),
              title: const Text('Experience Level'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMutedLight),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Experience filter coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewApplicantDetails(BuildContext context, ApplicationModel application) {
    context.push(
      '/jobs/${widget.jobId}/applicants/${application.id}',
      extra: application,
    ).then((result) {
      if (result == true) {
        ref.invalidate(jobApplicantsProvider(widget.jobId));
      }
    });
  }

  Future<void> _shortlistApplicant(ApplicationModel application) async {
    try {
      final repository = ref.read(applicationsRepositoryProvider);
      await repository.shortlistApplication(application.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Applicant shortlisted'), backgroundColor: AppColors.success),
        );
        ref.invalidate(jobApplicantsProvider(widget.jobId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectApplicant(ApplicationModel application) async {
    final applicantName = application.applicantDetails?.profile?.firstName ??
        'this applicant';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: const Text('Reject Application'),
        content: Text('Are you sure you want to reject $applicantName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(applicationsRepositoryProvider);
        await repository.rejectApplication(id: application.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application rejected')),
          );
          ref.invalidate(jobApplicantsProvider(widget.jobId));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppSpacing.roundedSm,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  final ApplicationModel application;
  final String jobId;
  final VoidCallback onTap;
  final VoidCallback onShortlist;
  final VoidCallback onReject;
  final VoidCallback onRate;

  const _ApplicantCard({
    required this.application,
    required this.jobId,
    required this.onTap,
    required this.onShortlist,
    required this.onReject,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicantDetails = application.applicantDetails;
    final profile = applicantDetails?.profile;
    final jobSeekerProfile = applicantDetails?.jobSeekerProfile;

    final applicantId = applicantDetails?.id ?? application.applicant;

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
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: profile?.avatar != null
                          ? NetworkImage(profile!.avatar!)
                          : null,
                      child: profile?.avatar == null
                          ? Text(
                        profile?.firstName?.substring(0, 1).toUpperCase() ?? 'A',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile?.firstName ?? ""} ${profile?.lastName ?? ""}'.trim().isEmpty
                                ? 'Applicant'
                                : '${profile?.firstName ?? ""} ${profile?.lastName ?? ""}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (profile?.headline != null)
                            Text(
                              profile!.headline!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: application.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.work_outline, size: 16, color: AppColors.textMutedLight),
                    const SizedBox(width: 4),
                    Text(
                      '${jobSeekerProfile?.experience?.length ?? 0} years exp',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Icon(Icons.schedule, size: 16, color: AppColors.textMutedLight),
                    const SizedBox(width: 4),
                    Text(
                      _getTimeAgo(application.createdAt ?? DateTime.now()),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                if (application.status == 'pending') ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onShortlist,
                          icon: const Icon(Icons.star_outline, size: 18),
                          label: const Text('Shortlist'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.accent),
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if ((application.status == 'accepted' || application.status == 'completed') &&
                    applicantId.isNotEmpty)
                  _buildRatingButton(context, ref, applicantId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButton(BuildContext context, WidgetRef ref, String applicantId) {
    final hasReviewedAsync = ref.watch(
      hasReviewedProvider(
        ReviewCheckParams(
          jobId: jobId,
          revieweeId: applicantId,
        ),
      ),
    );

    return hasReviewedAsync.when(
      data: (hasReviewed) {
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasReviewed ? null : onRate,
              icon: Icon(
                hasReviewed ? Icons.check_circle : Icons.star,
                size: 18,
              ),
              label: Text(hasReviewed ? 'Already Rated' : 'Rate Applicant'),
              style: OutlinedButton.styleFrom(
                foregroundColor: hasReviewed ? AppColors.success : AppColors.primary,
                side: BorderSide(color: hasReviewed ? AppColors.success : AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                disabledForegroundColor: AppColors.success.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: const Text('Checking...'),
          ),
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRate,
            icon: const Icon(Icons.star, size: 18),
            label: const Text('Rate Applicant'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
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
      case 'pending':
        color = AppColors.warning;
        text = 'Pending';
        break;
      case 'shortlisted':
        color = AppColors.accent;
        text = 'Shortlisted';
        break;
      case 'accepted':
        color = AppColors.success;
        text = 'Accepted';
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'Rejected';
        break;
      default:
        color = AppColors.textMutedLight;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ApplicationsRepository(dio);
});

final jobApplicantsProvider = FutureProvider.family<List<ApplicationModel>, String>(
      (ref, jobId) async {
    final repository = ref.watch(applicationsRepositoryProvider);
    return await repository.getJobApplicants(jobId: jobId);
  },
);
