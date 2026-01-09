// ============================================================================
// applications_page.dart - WITH DUPLICATE REVIEW PREVENTION
// lib/features/applications/presentation/pages/applications_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reviews/presentation/widgets/rating_dialog.dart';
import '../../../reviews/data/repositories/review_repository.dart'; // ✅ ADD THIS
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

                            // ✅ RATING BUTTON WITH DUPLICATE CHECK
                            if (!isEmployer && _canRateEmployer(application))
                              _buildRatingButton(context, ref, application),
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

  // ✅ CHECK: Can the user rate this employer?
  bool _canRateEmployer(ApplicationModel application) {
    final status = application.status.toLowerCase();
    // Only allow rating for completed, accepted, or rejected applications
    return status == 'rejected' || status == 'completed' || status == 'accepted';
  }

  // ✅ BUILD: Rating button with duplicate review check
  Widget _buildRatingButton(
      BuildContext context,
      WidgetRef ref,
      ApplicationModel application,
      ) {
    // Check if user has already reviewed this job
    final hasReviewedAsync = ref.watch(
      hasReviewedJobProvider(application.job),
    );

    return hasReviewedAsync.when(
      data: (hasReviewed) {
        if (hasReviewed) {
          // Already reviewed - show disabled button
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null, // Disabled
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Already Reviewed'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  disabledForegroundColor: Colors.green.withOpacity(0.5),
                ),
              ),
            ),
          );
        }

        // Not reviewed yet - show active button
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRatingDialog(context, ref, application),
              icon: const Icon(Icons.star_outline, size: 18),
              label: const Text('Rate Employer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber[700],
              ),
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 8),
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
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showRatingDialog(context, ref, application),
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('Rate Employer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber[700],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ SHOW: Rating dialog with better error handling
  void _showRatingDialog(
      BuildContext context,
      WidgetRef ref,
      ApplicationModel application,
      ) {
    print('🎯 === RATING DIALOG DATA EXTRACTION ===');

    String employerId = '';
    String employerName = 'Employer';
    String jobId = '';

    jobId = application.job;
    print('✅ Job ID from application.job: $jobId');

    final jobDetails = application.jobDetails;

    if (jobDetails != null) {
      print('✅ JobDetails found: ${jobDetails.title}');
      print('   Company: ${jobDetails.company.name}');

      employerId = jobDetails.postedBy;
      print('✅ Employer ID from postedBy: $employerId');

      if (jobDetails.postedByDetails != null) {
        final employer = jobDetails.postedByDetails!;
        final profile = employer.profile;

        if (profile != null) {
          employerName = profile.displayName ??
              '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();

          if (employerName.isEmpty || employerName == ' ') {
            employerName = employer.email.split('@')[0];
          }
        } else {
          employerName = employer.email.split('@')[0];
        }

        print('✅ Employer Name from postedByDetails: $employerName');
      } else {
        employerName = jobDetails.company.name;
        print('✅ Using Company Name (employer not populated): $employerName');
      }
    } else {
      print('⚠️ JobDetails is NULL - job was not populated');
      print('   Job ID (string): $jobId');
    }

    print('📊 FINAL VALUES:');
    print('   Job ID: $jobId');
    print('   Employer ID: $employerId');
    print('   Employer Name: $employerName');
    print('=================================');

    // Validation
    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot find job information. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      print('❌ VALIDATION FAILED: Job ID is empty');
      return;
    }

    if (employerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Job details not fully loaded'),
              SizedBox(height: 4),
              Text(
                'Pull down to refresh and try again',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Refresh',
            textColor: Colors.white,
            onPressed: () {
              ref.invalidate(myApplicationsProvider);
            },
          ),
        ),
      );
      print('❌ VALIDATION FAILED: Employer ID is empty');

      Future.delayed(const Duration(milliseconds: 500), () {
        ref.invalidate(myApplicationsProvider);
      });
      return;
    }

    print('✅ All validations passed - showing dialog');

    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        jobId: jobId,
        revieweeId: employerId,
        revieweeName: employerName,
      ),
    ).then((success) {
      if (success == true) {
        // Invalidate both applications and review check
        ref.invalidate(myApplicationsProvider);
        ref.invalidate(hasReviewedJobProvider(jobId));

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