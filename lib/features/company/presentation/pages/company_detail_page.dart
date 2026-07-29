// lib/features/company/presentation/pages/company_detail_page.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/company_provider.dart';

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
      backgroundColor: AppColors.backgroundLight,
      body: companyAsync.when(
        data: (company) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.surfaceLight,
              iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
              flexibleSpace: FlexibleSpaceBar(
                background: company.banner != null
                    ? Image.network(
                        company.banner!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: AppColors.borderLight,
                          child: const Icon(Icons.business, size: 80, color: AppColors.textMutedLight),
                        ),
                      )
                    : Container(
                        color: AppColors.borderLight,
                        child: const Icon(Icons.business, size: 80, color: AppColors.textMutedLight),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: AppSpacing.roundedLg,
                              border: Border.all(color: AppColors.surfaceLight, width: 4),
                              boxShadow: AppSpacing.cardShadow,
                            ),
                            child: company.logo != null
                                ? ClipRRect(
                                    borderRadius: AppSpacing.roundedSm,
                                    child: Image.network(
                                      company.logo!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) => const Icon(
                                        Icons.business,
                                        size: 50,
                                        color: AppColors.textMutedLight,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.business, size: 50, color: AppColors.textMutedLight),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimaryLight,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  company.industry ?? 'Industry not specified',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondaryLight,
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
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.work_outline,
                            label: 'Active Jobs',
                            value: '${company.stats?.activeJobs ?? 0}',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people_outline,
                            label: 'Employees',
                            value: company.companySize ?? 'N/A',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star_outline,
                            label: 'Rating',
                            value: company.stats?.averageRating != null
                                ? company.stats!.averageRating!.toStringAsFixed(1)
                                : 'N/A',
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // About Section
                  if (company.description != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: AppSpacing.roundedXl,
                        boxShadow: AppSpacing.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            company.description!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                  height: 1.6,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Company Info
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: AppSpacing.roundedXl,
                      boxShadow: AppSpacing.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (company.locations != null && company.locations!.isNotEmpty)
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: '${company.locations!.first.city}, ${company.locations!.first.country}',
                          ),
                        if (company.website != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _InfoRow(
                            icon: Icons.language,
                            label: 'Website',
                            value: company.website!,
                          ),
                        ],
                        if (company.email != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: company.email!,
                          ),
                        ],
                        if (company.contactPhone != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: company.contactPhone!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Active Jobs Button
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push('/jobs?company=$companyId');
                        },
                        icon: const Icon(Icons.work_outline, size: 20),
                        label: Text(
                          'View ${company.stats?.activeJobs ?? 0} Active Jobs',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading company: $error', style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
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
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: AppSpacing.roundedSm,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMutedLight,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryLight,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}