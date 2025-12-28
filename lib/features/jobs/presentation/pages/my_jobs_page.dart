// My Jobs Page
// ============================================================================
// my_jobs_page.dart
// lib/features/jobs/presentation/pages/my_jobs_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/jobs_provider.dart';
import '../widgets/job_card.dart';

class MyJobsPage extends ConsumerWidget {
  const MyJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myJobsAsync = ref.watch(myJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posted Jobs'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(myJobsProvider.notifier).loadJobs();
        },
        child: myJobsAsync.when(
          data: (jobs) {
            if (jobs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No jobs posted yet'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/jobs/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Post a Job'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return JobCard(
                  job: job,
                  onTap: () => context.push('/jobs/${job.id}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Job'),
                            content: const Text('Are you sure you want to delete this job?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          try {
                            await ref.read(myJobsProvider.notifier).deleteJob(job.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Job deleted successfully')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
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
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(myJobsProvider.notifier).loadJobs();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/jobs/create'),
        icon: const Icon(Icons.add),
        label: const Text('Post Job'),
      ),
    );
  }
}
