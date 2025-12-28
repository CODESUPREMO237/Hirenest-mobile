// ============================================================================
// applications_page.dart - ROLE-AWARE VERSION (FIXED)
// lib/features/applications/presentation/pages/applications_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/applications_provider.dart'; // ✅ FIXED PATH
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

                  // ✅ Get role safely for card display
                  final isEmployer = roleAsync.whenOrNull(
                    data: (role) => role == 'employer',
                  ) ?? false;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ApplicationCard(
                          application: applications[index],
                          isEmployerView: isEmployer,
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

  /// Build stats row based on role
  Widget _buildStatsRow(BuildContext context, Map<String, int> stats, String role) {
    // ✅ SAFE: Extract values with default fallback
    int getStatValue(String key) => stats[key] ?? 0;

    if (role == 'employer') {
      // Employer sees: Total, Pending, Reviewing, Interviewing
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
      // Job seeker sees: Total, Pending, Shortlisted, Rejected
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

  /// Build empty state based on role
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