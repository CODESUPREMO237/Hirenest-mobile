// ============================================================================
// applications_page.dart - WITH RATING FEATURE
// lib/features/applications/presentation/pages/applications_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reviews/presentation/widgets/rating_dialog.dart';
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
      appBar: AppBar(
        title: roleAsync.when(
          data: (role) => Text(
              role == 'employer'
                  ? 'Applications Received'
                  : 'My Applications'
          ),
          loading: () => const Text('Applications'),
          error: (_, __) => const Text('Applications'),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats Summary Section
          statsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: roleAsync.when(
                data: (role) => _buildStatsRow(context, stats, role),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // Applications List Section
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myApplicationsProvider);
                ref.invalidate(applicationStatsProvider);
                await ref.read(myApplicationsProvider.future);
              },
              child: applicationsAsync.when(
                data: (applications) {
                  if (applications.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: roleAsync.when(
                            data: (role) => _buildEmptyState(context, role),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Text('Error loading role'),
                          ),
                        ),
                      ],
                    );
                  }

                  final isEmployer = roleAsync.whenOrNull(
                    data: (role) => role == 'employer',
                  ) ?? false;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      final application = applications[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ApplicationCard(
                              application: application,
                              isEmployerView: isEmployer,
                            ),

                            // ✅ ADD RATING BUTTON FOR JOB SEEKERS
                            if (!isEmployer && _canRateEmployer(application))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showRatingDialog(
                                      context,
                                      ref,
                                      application,
                                    ),
                                    icon: const Icon(Icons.star_outline, size: 18),
                                    label: const Text('Rate Employer'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.amber[700],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Error: $error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.invalidate(myApplicationsProvider),
                        child: const Text('Retry'),
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

  // ✅ NEW: Check if job seeker can rate employer
  bool _canRateEmployer(dynamic application) {
    // Allow rating if:
    // 1. Application was rejected (to rate interview experience)
    // 2. Application was accepted and job is completed
    final status = application.status?.toLowerCase() ?? '';
    return status == 'rejected' || status == 'completed' || status == 'accepted';
  }

  // ✅ NEW: Show rating dialog
  void _showRatingDialog(
      BuildContext context,
      WidgetRef ref,
      dynamic application,
      ) {
    // Extract employer info safely
    final employerId = application.job?.employer?.id ??
        application.job?.employerId ?? '';
    final employerName = application.job?.company?.name ??
        application.job?.employer?.name ??
        'Employer';
    final jobId = application.job?.id ?? application.jobId ?? '';

    if (employerId.isEmpty || jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot submit rating: Missing employer or job information'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        jobId: jobId,
        revieweeId: employerId,
        revieweeName: employerName,
      ),
    ).then((success) {
      if (success == true) {
        // Refresh applications list to show updated status
        ref.invalidate(myApplicationsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Widget _buildStatsRow(BuildContext context, Map<String, int> stats, String role) {
    int getStatValue(String key) => stats[key] ?? 0;

    if (role == 'employer') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem('Total', getStatValue('total'), Colors.blue),
          _StatItem('Pending', getStatValue('pending'), Colors.orange),
          _StatItem('Reviewing', getStatValue('reviewing'), Colors.purple),
          _StatItem('Interviewing', getStatValue('interviewing'), Colors.green),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem('Total', getStatValue('total'), Colors.blue),
          _StatItem('Pending', getStatValue('pending'), Colors.orange),
          _StatItem('Shortlisted', getStatValue('shortlisted'), Colors.purple),
          _StatItem('Rejected', getStatValue('rejected'), Colors.red),
        ],
      );
    }
  }

  Widget _buildEmptyState(BuildContext context, String role) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          role == 'employer'
              ? Icons.people_outline
              : Icons.description_outlined,
          size: 80,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        Text(
          role == 'employer'
              ? 'No applications received yet'
              : 'No applications yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          role == 'employer'
              ? 'Post jobs to receive applications from candidates'
              : 'Start applying to jobs to see them here!',
          textAlign: TextAlign.center,
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}