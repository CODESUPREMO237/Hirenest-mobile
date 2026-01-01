// ============================================================================
// job_applicants_page.dart - WITH RATING FEATURE FOR EMPLOYERS
// lib/features/jobs/presentation/pages/job_applicants_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../applications/data/models/application_model.dart';
import '../../../applications/data/repositories/applications_repository.dart';
import '../../../../core/network/dio_client.dart';
import '../../../reviews/presentation/widgets/rating_dialog.dart';


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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applicants'),
            Text(
              widget.jobTitle,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
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
            icon: const Icon(Icons.filter_list),
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
            },
            child: Column(
              children: [
                _buildStatsSummary(applicants),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredApplicants.length,
                    itemBuilder: (context, index) {
                      return _ApplicantCard(
                        application: filteredApplicants[index],
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
                        // ✅ ADD RATING CALLBACK
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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading applicants: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(jobApplicantsProvider(widget.jobId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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

  // ✅ NEW: Rate applicant method
  void _rateApplicant(BuildContext context, ApplicationModel application) {
    final applicantId = application.applicantDetails?.id ?? application.applicant;
    final applicantName = application.applicantDetails?.profile?.firstName ?? 'Applicant';

    if (applicantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit rating: Missing applicant information'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.people,
            label: 'Total',
            value: total.toString(),
            color: Colors.blue,
          ),
          _StatItem(
            icon: Icons.schedule,
            label: 'Pending',
            value: pending.toString(),
            color: Colors.orange,
          ),
          _StatItem(
            icon: Icons.star,
            label: 'Shortlisted',
            value: shortlisted.toString(),
            color: Colors.purple,
          ),
          _StatItem(
            icon: Icons.check_circle,
            label: 'Reviewed',
            value: reviewed.toString(),
            color: Colors.green,
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
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No applicants yet'
                : 'No ${_selectedFilter} applicants',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Applications will appear here when candidates apply',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Applicants',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort by: Most Recent'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sorting by most recent')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Experience Level'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
    );
  }

  Future<void> _shortlistApplicant(ApplicationModel application) async {
    try {
      final repository = ref.read(applicationsRepositoryProvider);
      await repository.shortlistApplication(application.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Applicant shortlisted')),
        );
        ref.invalidate(jobApplicantsProvider(widget.jobId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        title: const Text('Reject Application'),
        content: Text('Are you sure you want to reject $applicantName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

// Stat Item Widget
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
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
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// ✅ UPDATED: Applicant Card with Rating Button
class _ApplicantCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback onTap;
  final VoidCallback onShortlist;
  final VoidCallback onReject;
  final VoidCallback onRate; // ✅ NEW

  const _ApplicantCard({
    required this.application,
    required this.onTap,
    required this.onShortlist,
    required this.onReject,
    required this.onRate, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    final applicantDetails = application.applicantDetails;
    final profile = applicantDetails?.profile;
    final jobSeekerProfile = applicantDetails?.jobSeekerProfile;

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
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profile?.avatar != null
                        ? NetworkImage(profile!.avatar!)
                        : null,
                    child: profile?.avatar == null
                        ? Text(
                      profile?.firstName?.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (profile?.headline != null)
                          Text(
                            profile!.headline!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${jobSeekerProfile?.experience?.length ?? 0} years exp',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeAgo(application.createdAt ?? DateTime.now()),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons
              if (application.status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShortlist,
                        icon: const Icon(Icons.star_outline, size: 18),
                        label: const Text('Shortlist'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),

              // ✅ NEW: Show rating button if accepted
              if (application.status == 'accepted')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRate,
                      icon: const Icon(Icons.star, size: 18),
                      label: const Text('Rate Applicant'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber[700],
                      ),
                    ),
                  ),
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

// Status Badge
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'shortlisted':
        color = Colors.purple;
        text = 'Shortlisted';
        break;
      case 'accepted':
        color = Colors.green;
        text = 'Accepted';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
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
        border: Border.all(color: color.withOpacity(0.3)),
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