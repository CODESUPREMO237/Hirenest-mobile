// ============================================================================
// ENHANCED PROFILE PAGE WITH LOGOUT HANDLER
// lib/features/profile/presentation/pages/profile_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/payment_service.dart';
import '../../../applications/presentation/providers/applications_provider.dart';
import '../../../reviews/presentation/widgets/rating_display_widget.dart';
import '../providers/profile_provider.dart';
import '../../helpers/logout_handler.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final balanceAsync = ref.watch(balanceProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimaryLight),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final completionData = _calculateProfileCompletion(profile);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(balanceProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar with Completion Ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: CircularProgressIndicator(
                                value: completionData['percentage'] / 100,
                                strokeWidth: 3,
                                backgroundColor: AppColors.borderLight,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  completionData['percentage'] == 100
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(alpha: 0.1),
                                image: profile.profile?.avatar != null
                                    ? DecorationImage(
                                        image: NetworkImage(profile.profile!.avatar!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: profile.profile?.avatar == null
                                  ? Center(
                                      child: Text(
                                        _getInitials(profile.email),
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    )
                                  : null,
                            ),
                            if (completionData['percentage'] < 100)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: const BoxDecoration(
                                    color: AppColors.warning,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${completionData['percentage'].toInt()}%',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                            if (completionData['percentage'] == 100)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: AppColors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        Text(
                          profile.profile?.firstName != null
                              ? '${profile.profile!.firstName} ${profile.profile!.lastName ?? ''}'
                              : profile.email,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.roundedFull,
                          ),
                          child: Text(
                            _getRoleText(profile.role),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        if (profile.ratingsAverage != null &&
                            profile.ratingsQuantity != null &&
                            profile.ratingsQuantity! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: AppSpacing.roundedFull,
                            ),
                            child: RatingDisplayWidget(
                              rating: profile.ratingsAverage,
                              count: profile.ratingsQuantity,
                              size: 18,
                              color: AppColors.warning,
                            ),
                          ),

                        if (profile.marketplaceStats?.sellerRating != null &&
                            profile.marketplaceStats!.sellerRating!.count > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: AppSpacing.roundedFull,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.store, color: AppColors.textSecondaryLight, size: 16),
                                  const SizedBox(width: AppSpacing.sm),
                                  RatingDisplayWidget(
                                    rating: profile.marketplaceStats!.sellerRating!.average,
                                    count: profile.marketplaceStats!.sellerRating!.count,
                                    size: 16,
                                    color: AppColors.warning,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (completionData['percentage'] < 100)
                    _buildCompletionAlert(context, completionData),

                  if (profile.role == 'jobseeker' || profile.role == 'employer')
                    balanceAsync.when(
                      data: (balance) => _buildBalanceCard(context, balance),
                      loading: () => const SizedBox.shrink(),
                      error: (error, _) => const SizedBox.shrink(),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.shopping_bag_outlined,
                            '${profile.marketplaceStats?.activeProducts ?? 0}',
                            'Products',
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.work_outline,
                            ref.watch(applicationStatsProvider).maybeWhen(
                              data: (stats) => '${stats['total'] ?? 0}',
                              orElse: () => '0',
                            ),
                            'Applications',
                            AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.star_outline,
                            (profile.ratingsAverage ?? 0.0).toStringAsFixed(1),
                            'Job Rating',
                            AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildMenuSection(
                    context,
                    'Account',
                    [
                      _MenuItem(
                        Icons.person_outline,
                        'Edit Profile',
                        () => context.push('/profile/edit'),
                      ),
                      _MenuItem(
                        Icons.shopping_bag_outlined,
                        'My Products',
                        () => context.push('/marketplace/my-products'),
                      ),
                      _MenuItem(
                        Icons.shopping_cart_outlined,
                        'My Purchases',
                        () => context.push('/marketplace/my-orders'),
                      ),
                      _MenuItem(
                        Icons.storefront_outlined,
                        'My Sales',
                        () => context.push('/marketplace/my-sales'),
                      ),
                      _MenuItem(
                        Icons.work_outline,
                        'My Applications',
                        () => context.push('/applications'),
                      ),
                      _MenuItem(
                        Icons.receipt_long_outlined,
                        'Transaction History',
                        () => context.push('/profile/transactions'),
                      ),
                    ],
                  ),

                  _buildMenuSection(
                    context,
                    'Settings',
                    [
                      _MenuItem(
                        Icons.notifications_outlined,
                        'Notifications',
                        () => context.push('/profile/notifications'),
                      ),
                      _MenuItem(
                        Icons.privacy_tip_outlined,
                        'Privacy & Security',
                        () => context.push('/profile/privacy-security'),
                      ),
                      _MenuItem(
                        Icons.help_outline,
                        'Help & Support',
                        () => context.push('/profile/help-support'),
                      ),
                      _MenuItem(
                        Icons.info_outline,
                        'About',
                        () => context.push('/profile/about'),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: OutlinedButton.icon(
                      onPressed: () => handleLogout(context, ref),
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.borderLight),
                        backgroundColor: AppColors.surfaceLight,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.roundedMd,
                        ),
                        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Error: $error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateProfileCompletion(dynamic profile) {
    int completed = 0;
    int total = 0;
    List<String> missing = [];

    if (profile.profile?.firstName != null && profile.profile!.firstName!.isNotEmpty) {
      completed += 10;
    } else {
      missing.add('First Name');
    }
    total += 10;

    if (profile.profile?.lastName != null && profile.profile!.lastName!.isNotEmpty) {
      completed += 10;
    } else {
      missing.add('Last Name');
    }
    total += 10;

    if (profile.profile?.phone != null && profile.profile!.phone!.isNotEmpty) {
      completed += 10;
    } else {
      missing.add('Phone Number');
    }
    total += 10;

    if (profile.profile?.location?.city != null) {
      completed += 10;
    } else {
      missing.add('City');
    }
    total += 10;

    if (profile.profile?.location?.country != null) {
      completed += 10;
    } else {
      missing.add('Country');
    }
    total += 10;

    if (profile.profile?.bio != null && profile.profile!.bio!.isNotEmpty) {
      completed += 10;
    } else {
      missing.add('Bio');
    }
    total += 10;

    if (profile.profile?.avatar != null && profile.profile!.avatar!.isNotEmpty) {
      completed += 10;
    } else {
      missing.add('Profile Picture');
    }
    total += 10;

    if (profile.role?.toLowerCase() == 'jobseeker') {
      if (profile.jobSeekerProfile?.skills != null && profile.jobSeekerProfile!.skills!.isNotEmpty) {
        completed += 10;
      } else {
        missing.add('Skills');
      }
      total += 10;

      if (profile.jobSeekerProfile?.education != null && profile.jobSeekerProfile!.education!.isNotEmpty) {
        completed += 10;
      } else {
        missing.add('Education');
      }
      total += 10;

      if (profile.jobSeekerProfile?.experience != null && profile.jobSeekerProfile!.experience!.isNotEmpty) {
        completed += 10;
      } else {
        missing.add('Work Experience');
      }
      total += 10;
    }

    final percentage = (completed / total * 100).toDouble();

    return {
      'percentage': percentage,
      'completed': completed,
      'total': total,
      'missing': missing,
    };
  }

  Widget _buildCompletionAlert(BuildContext context, Map<String, dynamic> completionData) {
    final percentage = completionData['percentage'] as double;
    final missing = completionData['missing'] as List<String>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Complete Your Profile (${percentage.toInt()}%)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Add these details to improve your visibility:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: missing.take(3).map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.roundedFull,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              );
            }).toList(),
          ),
          if (missing.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '+${missing.length - 3} more',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMutedLight,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Complete Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, dynamic balance) {
    return InkWell(
      onTap: () => context.push('/profile/balance'),
      borderRadius: AppSpacing.roundedLg,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: AppSpacing.roundedLg,
          boxShadow: AppSpacing.elevatedShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Balance',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  NumberFormat.currency(
                    symbol: balance.currency,
                    decimalDigits: 0,
                  ).format(balance.availableForWithdrawal),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Column(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppColors.white, size: 32),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    'Withdraw',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
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

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.sm),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMutedLight,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppSpacing.cardShadow,
          ),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Icon(item.icon, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMutedLight, size: 20),
                    onTap: item.onTap,
                    shape: RoundedRectangleBorder(
                      borderRadius: isLast
                          ? const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusLg))
                          : items.first == item
                              ? const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg))
                              : BorderRadius.zero,
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: AppSpacing.xl + 20,
                      color: AppColors.borderLight,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getInitials(String email) {
    return email.substring(0, 2).toUpperCase();
  }

  String _getRoleText(String role) {
    switch (role.toLowerCase()) {
      case 'job_seeker':
      case 'jobseeker':
        return 'Job Seeker';
      case 'employer':
        return 'Employer';
      default:
        return role;
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.title, this.onTap);
}

final balanceProvider = FutureProvider.autoDispose<BalanceResponse>((ref) async {
  final paymentService = ref.read(paymentServiceProvider);
  return await paymentService.getBalance();
});