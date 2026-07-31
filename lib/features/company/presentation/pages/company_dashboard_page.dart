// lib/features/company/presentation/pages/company_dashboard_page.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/company_provider.dart';
import '../../data/models/company_model.dart';

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(myCompanyProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Company Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryLight),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback to main layout if the stack was cleared
              context.go('/');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimaryLight),
            onPressed: () => context.push('/profile/notifications'),
          ),
        ],
      ),
      body: companyAsync.when(
        data: (company) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceLight,
            onRefresh: () => ref.refresh(myCompanyProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyHeaderCard(company: company),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Company Stats',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildStatsGrid(company),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildQuickActions(context),
                  const SizedBox(height: AppSpacing.xl),
                  _CompanyInfoCard(company: company),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) {
          AppLogger.error('Dashboard Error', error: error, stackTrace: stack);
          return CustomErrorWidget(
            message: 'Failed to load dashboard: ${error.toString()}',
            onRetry: () => ref.invalidate(myCompanyProvider),
          );
        },
      ),
      floatingActionButton: companyAsync.maybeWhen(
        data: (company) => FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          onPressed: () => context.push('/company/edit'),
          icon: const Icon(Icons.edit, size: 20),
          label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildStatsGrid(CompanyModel company) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          icon: Icons.work_outline,
          title: 'Active Jobs',
          value: '${company.stats?.activeJobs ?? 0}',
          color: AppColors.primary,
        ),
        _StatCard(
          icon: Icons.people_outline,
          title: 'Size',
          value: company.companySize ?? 'N/A',
          color: AppColors.success,
        ),
        _StatCard(
          icon: Icons.location_on_outlined,
          title: 'Locations',
          value: '${company.locations?.length ?? 0}',
          color: AppColors.accent,
        ),
        _StatCard(
          icon: Icons.star_outline,
          title: 'Rating',
          value: company.stats?.averageRating?.toStringAsFixed(1) ?? '0.0',
          color: AppColors.warning,
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
                color: AppColors.primary,
                onPressed: () => context.push('/jobs/create'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionButton(
                icon: Icons.list_alt,
                label: 'View Jobs',
                color: AppColors.success,
                onPressed: () => context.push('/jobs'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.person_add_outlined,
                label: 'Admins',
                color: AppColors.accent,
                onPressed: () {
                  AppLogger.debug('Navigating to manage admins');
                  context.push('/company/manage-admins');
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ActionButton(
                icon: Icons.bar_chart_outlined,
                label: 'Analytics',
                color: AppColors.warning,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedXl,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          if (company.banner != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
              child: Image.network(
                company.banner!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 120, color: AppColors.borderLight),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: company.logo != null
                      ? ClipRRect(
                          borderRadius: AppSpacing.roundedLg,
                          child: Image.network(company.logo!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.business, color: AppColors.textMutedLight, size: 32),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company.industry ?? 'General',
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
    return Container(
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
          const SizedBox(height: AppSpacing.md),
          _InfoRow(icon: Icons.description_outlined, label: 'About', value: company.description ?? 'No description'),
          const Divider(height: AppSpacing.xl, color: AppColors.borderLight),
          _InfoRow(icon: Icons.language, label: 'Website', value: company.website ?? 'N/A'),
          const Divider(height: AppSpacing.xl, color: AppColors.borderLight),
          _InfoRow(icon: Icons.email_outlined, label: 'Contact', value: company.email ?? 'N/A'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textMutedLight),
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
                      color: AppColors.textPrimaryLight,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
          ),
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

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppSpacing.roundedLg,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppSpacing.roundedLg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.2)),
            borderRadius: AppSpacing.roundedLg,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
