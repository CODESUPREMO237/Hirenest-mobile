// lib/features/jobs/presentation/pages/job_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// Providers
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/jobs_provider.dart';

// Widgets & Models
import '../widgets/job_details_section.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs_repository.dart'; // Ensure you have this for delete

class JobDetailPage extends ConsumerWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final userAsync = ref.watch(currentUserProvider);
    final currentUser = userAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/jobs'),
        ),
      ),
      body: jobAsync.when(
        data: (job) {
          // --- DEBUG LOGS ---
          debugPrint('--- Ownership Debug ---');
          debugPrint('Current User ID: ${currentUser?.id}');
          debugPrint('Job PostedBy: ${job.postedBy}');
          debugPrint('Match: ${currentUser?.id.toString() == job.postedBy.toString()}');
          debugPrint('-----------------------');

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(jobDetailProvider(jobId)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyHeader(context, job),
                  _buildTitleSection(context, job),
                  if (job.salary != null && job.salary!.showSalary) _buildSalaryCard(job),

                  const SizedBox(height: 16),

                  // Stats Card
                  if (job.stats != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStatsCard(job),
                    ),

                  const SizedBox(height: 16),
                  JobDetailsSection(job: job),
                  const SizedBox(height: 120), // Space for bottom buttons
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: jobAsync.maybeWhen(
        data: (job) {
          final currentUserId = currentUser?.id?.toString();

          // --- NEW LOGIC FOR POPULATED postedBy ---
          String? postedById;

          if (job.postedBy is String) {
            postedById = job.postedBy.toString();
          } else if (job.postedBy is Map) {
            // If backend returns an object, try to find the ID inside it
            postedById = (job.postedBy as Map)['_id']?.toString() ??
                (job.postedBy as Map)['id']?.toString();
          }

          // Fallback: If your JobModel has a specific field for this, use it
          // Some models use job.postedBy.id if it's a nested class

          final isOwner = currentUserId != null && postedById != null && currentUserId == postedById;
          final isEmployer = currentUser?.role == 'employer';

          // DEBUG to verify fix
          debugPrint('Fixed PostedBy ID: $postedById');
          debugPrint('Is Owner: $isOwner');

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. View Applicants Button
            ElevatedButton.icon(
              onPressed: () => context.push('/jobs/${job.id}/applicants', extra: job.title),
              icon: const Icon(Icons.people_alt_outlined),
              label: Text('View Applicants (${job.stats?.applications ?? 0})'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // 2. Edit Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/jobs/${job.id}/edit'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 3. Delete Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref, job),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // --- DELETE LOGIC ---

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, JobModel job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job Posting?'),
        content: const Text('This action cannot be undone. All applications for this job will also be inaccessible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Call your repository to delete
        await ref.read(jobsRepositoryProvider).deleteJob(job.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job deleted successfully')));
          context.go('/jobs'); // Redirect to job list
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting job: $e')));
        }
      }
    }
  }

  // --- REMAINING UI HELPERS ---

  Widget _buildStatsCard(JobModel job) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('👁️ Total Views', '${job.stats?.views ?? 0}'),
            _buildStatRow('👤 Unique Views', '${job.stats?.uniqueViews ?? 0}'),
            _buildStatRow('📝 Applications', '${job.stats?.applications ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCompanyHeader(BuildContext context, JobModel job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Column(
        children: [
          if (job.company.logo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(job.company.logo!, width: 60, height: 60, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Text(job.company.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, JobModel job) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(job.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildJobChip(job.jobType, Colors.blue),
              _buildJobChip(job.location.type, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobChip(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
    );
  }

  Widget _buildSalaryCard(JobModel job) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        tileColor: Colors.grey.shade100,
        leading: const Icon(Icons.payments, color: Colors.green),
        title: const Text('Salary'),
        subtitle: Text('${job.salary!.min} - ${job.salary!.max} ${job.salary!.currency}'),
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context, JobModel job) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: job.isApplied ? null : () => context.push('/jobs/${job.id}/apply'),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        child: Text(job.isApplied ? 'Already Applied' : 'Apply Now'),
      ),
    );
  }
}