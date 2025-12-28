// Company Detail Page
// lib/features/company/presentation/pages/company_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/company_provider.dart';
import '../../data/models/company_model.dart';

class CompanyDetailPage extends ConsumerWidget {
  final String companyId;

  const CompanyDetailPage({
    super.key,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProvider(companyId));

    return Scaffold(
      body: companyAsync.when(
        data: (company) => CustomScrollView(
          slivers: [
            // App Bar with Banner
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: company.banner != null
                    ? Image.network(
                  company.banner!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.business, size: 80, color: Colors.grey),
                  ),
                )
                    : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.business, size: 80, color: Colors.grey),
                ),
              ),
            ),

            // Company Info
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Basic Info
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Logo
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: company.logo != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                company.logo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => Icon(
                                  Icons.business,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                              ),
                            )
                                : Icon(Icons.business, size: 50, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 16),
                          // Company Name and Industry
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  company.industry ?? 'Industry not specified',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.work_outline,
                            label: 'Active Jobs',
                            value: '${company.stats?.activeJobs ?? 0}',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people_outline,
                            label: 'Employees',
                            value: company.companySize ?? 'N/A',
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star_outline,
                            label: 'Rating',
                            value: company.stats?.averageRating != null
                                ? company.stats!.averageRating!.toStringAsFixed(1)
                                : 'N/A',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // About Section
                  if (company.description != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            company.description!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],

                  // Company Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (company.locations != null && company.locations!.isNotEmpty)
                          _InfoRow(
                            icon: Icons.location_on,
                            label: 'Location',
                            value:
                            '${company.locations!.first.city}, ${company.locations!.first.country}',
                          ),
                        if (company.website != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.language,
                            label: 'Website',
                            value: company.website!,
                          ),
                        ],
                        if (company.email != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: company.email!,
                          ),
                        ],
                        if (company.contactPhone != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.phone,
                            label: 'Phone',
                            value: company.contactPhone!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Active Jobs Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to company jobs
                          context.push('/jobs?company=$companyId');
                        },
                        icon: const Icon(Icons.work_outline),
                        label: Text(
                          'View ${company.stats?.activeJobs ?? 0} Active Jobs',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading company: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(companyProvider(companyId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}