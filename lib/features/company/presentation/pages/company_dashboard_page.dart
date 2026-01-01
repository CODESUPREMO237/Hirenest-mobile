// ============================================================================
// FIXED COMPANY DASHBOARD PAGE
// lib/features/company/presentation/pages/company_dashboard_page.dart
// ============================================================================

// ============================================================================
// UPDATED COMPANY DASHBOARD PAGE WITH CUSTOM ERROR WIDGET
// lib/features/company/presentation/pages/company_dashboard_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/error_widget.dart'; // Ensure this matches your path
import '../providers/company_provider.dart';
import '../../data/models/company_model.dart';

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(myCompanyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/profile/notifications'),
          ),
        ],
      ),
      body: companyAsync.when(
        data: (company) {
          if (company == null) {
            return _buildNoCompanyView(context, ref);
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(myCompanyProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyHeaderCard(company: company),
                  const SizedBox(height: 24),
                  Text(
                    'Company Stats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsGrid(company),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _CompanyInfoCard(company: company),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          AppLogger.error('Dashboard Error', error: error, stackTrace: stack);

          // Using your CustomErrorWidget here
          return CustomErrorWidget(
            message: 'Failed to load dashboard: ${error.toString()}',
            onRetry: () => ref.invalidate(myCompanyProvider),
          );
        },
      ),
      floatingActionButton: companyAsync.maybeWhen(
        data: (company) => company != null
            ? FloatingActionButton.extended(
          onPressed: () => context.push('/company/edit'),
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
        )
            : null,
        orElse: () => null,
      ),
    );
  }



  Widget _buildNoCompanyView(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(myCompanyProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Icon(Icons.business_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No company profile found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Create a company profile to manage jobs and teams',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/company/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Company Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(CompanyModel company) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.work_outline,
          title: 'Active Jobs',
          value: '${company.stats?.activeJobs ?? 0}',
          color: Colors.blue,
        ),
        _StatCard(
          icon: Icons.people_outline,
          title: 'Size',
          value: company.companySize ?? 'N/A',
          color: Colors.green,
        ),
        _StatCard(
          icon: Icons.location_on_outlined,
          title: 'Locations',
          value: '${company.locations?.length ?? 0}',
          color: Colors.purple,
        ),
        _StatCard(
          icon: Icons.star_outline,
          title: 'Rating',
          value: company.stats?.averageRating?.toStringAsFixed(1) ?? '0.0',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.work_outline,
                label: 'Post Job',
                color: Colors.blue,
                onPressed: () => context.push('/jobs/create'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.list_alt,
                label: 'View Jobs',
                color: Colors.green,
                onPressed: () => context.push('/jobs'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.person_add_outlined,
                label: 'Admins',
                color: Colors.purple,
                onPressed: () {
                  AppLogger.debug('Navigating to manage admins');
                  context.push('/company/manage-admins');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.bar_chart_outlined,
                label: 'Analytics',
                color: Colors.orange,
                onPressed: () => context.push('/analytics'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompanyHeaderCard extends StatelessWidget {
  final CompanyModel company;
  const _CompanyHeaderCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          if (company.banner != null)
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                company.banner!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 120, color: Colors.grey[300]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: company.logo != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(company.logo!, fit: BoxFit.cover),
                  )
                      : const Icon(Icons.business, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(company.industry ?? 'General',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyInfoCard extends StatelessWidget {
  final CompanyModel company;
  const _CompanyInfoCard({required this.company});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
                icon: Icons.description,
                label: 'About',
                value: company.description ?? 'No description'),
            const Divider(),
            _InfoRow(
                icon: Icons.language,
                label: 'Website',
                value: company.website ?? 'N/A'),
            const Divider(),
            _InfoRow(
                icon: Icons.email,
                label: 'Contact',
                value: company.email ?? 'N/A'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
        required this.title,
        required this.value,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}