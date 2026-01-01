// ============================================================================
// ENHANCED PROFILE PAGE WITH WORKING RATINGS & COMPLETION INDICATOR
// lib/features/profile/presentation/pages/profile_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/payment_service.dart';
import '../../../applications/presentation/providers/applications_provider.dart';
import '../../../reviews/presentation/widgets/rating_summary_widget.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final balanceAsync = ref.watch(balanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          // Calculate profile completion
          final completionData = _calculateProfileCompletion(profile);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileProvider);
              ref.invalidate(balanceProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header with Completion Indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar with Completion Ring
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Completion Ring
                            SizedBox(
                              width: 110,
                              height: 110,
                              child: CircularProgressIndicator(
                                value: completionData['percentage'] / 100,
                                strokeWidth: 4,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  completionData['percentage'] == 100
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                ),
                              ),
                            ),
                            // Avatar
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: profile.profile?.avatar != null
                                  ? NetworkImage(profile.profile!.avatar!)
                                  : null,
                              child: profile.profile?.avatar == null
                                  ? Text(
                                _getInitials(profile.email),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              )
                                  : null,
                            ),
                            // Completion Badge
                            if (completionData['percentage'] < 100)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${completionData['percentage'].toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          profile.profile?.firstName != null
                              ? '${profile.profile!.firstName} ${profile.profile!.lastName ?? ''}'
                              : profile.email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRoleText(profile.role),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Email
                        Text(
                          profile.email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),


                        // ✅ FIXED: Job Performance Rating (for job seekers)
                        // ============================================================================
                        // ✅ FIXED: Job Performance Rating (for job seekers)

                        if (profile.profile?.ratingsAverage != null &&
                            profile.profile?.ratingsQuantity != null &&
                            profile.profile!.ratingsQuantity! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: RatingSummaryWidget(
                              // ✅ Correct path: profile.profile.ratingsAverage
                              rating: profile.profile!.ratingsAverage,
                              count: profile.profile!.ratingsQuantity,
                              size: 18,
                            ),
                          ),

                        // ⭐ Marketplace Rating (for sellers/employers)
                        if (profile.marketplaceStats?.sellerRating != null &&
                            profile.marketplaceStats!.sellerRating!.count > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.store,
                                      color: Colors.white,
                                      size: 16
                                  ),
                                  const SizedBox(width: 6),
                                  RatingSummaryWidget(
                                    rating: profile.marketplaceStats!
                                        .sellerRating!.average,
                                    count: profile.marketplaceStats!
                                        .sellerRating!.count,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 🎯 Profile Completion Alert
                  if (completionData['percentage'] < 100)
                    _buildCompletionAlert(context, completionData),

                  // Balance Card (for sellers)
                  if (profile.role == 'jobseeker' || profile.role == 'employer')
                    balanceAsync.when(
                      data: (balance) => _buildBalanceCard(context, balance),
                      loading: () => const SizedBox.shrink(),
                      error: (error, _) => const SizedBox.shrink(),
                    ),

                  // Profile Stats with Rating
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.shopping_bag_outlined,
                            '${profile.marketplaceStats?.activeProducts ?? 0}',
                            'Products',
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.work_outline,
                            ref.watch(applicationStatsProvider).maybeWhen(
                              data: (stats) => '${stats['total'] ?? 0}',
                              orElse: () => '0',
                            ),
                            'Applications',
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            Icons.star_outline,
                            (profile.profile?.ratingsAverage ?? 0.0)
                                .toStringAsFixed(1),
                            'Job Rating',
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Items
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

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, ref),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
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
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 🎯 PROFILE COMPLETION CALCULATOR
  // ============================================================================
  Map<String, dynamic> _calculateProfileCompletion(dynamic profile) {
    int completed = 0;
    int total = 0;
    List<String> missing = [];

    // Basic profile fields (30%)
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

    // Location (20%)
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

    // Bio (10%)
    if (profile.profile?.bio != null && profile.profile!.bio!.isNotEmpty) {
      completed += 10;
    } else {
      missing.add('Bio');
    }
    total += 10;

    // Avatar (10%)
    if (profile.profile?.avatar != null && profile.profile!.avatar!.isNotEmpty) {
      completed += 10;
    } else {
      missing.add('Profile Picture');
    }
    total += 10;

    // Role-specific completion
    if (profile.role?.toLowerCase() == 'jobseeker') {
      // Skills (10%)
      if (profile.jobSeekerProfile?.skills != null &&
          profile.jobSeekerProfile!.skills!.isNotEmpty) {
        completed += 10;
      } else {
        missing.add('Skills');
      }
      total += 10;

      // Education (10%)
      if (profile.jobSeekerProfile?.education != null &&
          profile.jobSeekerProfile!.education!.isNotEmpty) {
        completed += 10;
      } else {
        missing.add('Education');
      }
      total += 10;

      // Experience (10%)
      if (profile.jobSeekerProfile?.experience != null &&
          profile.jobSeekerProfile!.experience!.isNotEmpty) {
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

  // ============================================================================
  // 🎯 COMPLETION ALERT WIDGET
  // ============================================================================
  Widget _buildCompletionAlert(
      BuildContext context,
      Map<String, dynamic> completionData,
      ) {
    final percentage = completionData['percentage'] as double;
    final missing = completionData['missing'] as List<String>;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete Your Profile (${percentage.toInt()}%)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Add these details to improve your visibility:',
            style: TextStyle(color: Colors.orange[800], fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missing.take(3).map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          if (missing.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${missing.length - 3} more',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Complete Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange[800],
                side: BorderSide(color: Colors.orange[800]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ⭐ RATING DISPLAY WIDGET
  // ============================================================================
  Widget _buildRatingDisplay(double rating, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' ($count ${count == 1 ? 'review' : 'reviews'})',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Rest of the widget methods remain the same...
  Widget _buildBalanceCard(BuildContext context, dynamic balance) {
    return InkWell(
      onTap: () => context.push('/profile/balance'),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[700]!, Colors.green[500]!],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormat.currency(
                    symbol: balance.currency,
                    decimalDigits: 0,
                  ).format(balance.availableForWithdrawal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Withdraw',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
      BuildContext context,
      String title,
      List<_MenuItem> items,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: items.map((item) {
              final isLast = items.last == item;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: item.onTap,
                  ),
                  if (!isLast) const Divider(height: 1),
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
    switch (role) {
      case 'job_seeker':
      case 'jobseeker':
        return 'Job Seeker';
      case 'employer':
        return 'Employer';
      default:
        return role;
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                const Center(child: CircularProgressIndicator()),
              );
              try {
                await ref.read(logoutControllerProvider).logout();
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/auth/login');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout error: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.title, this.onTap);
}

final balanceProvider =
FutureProvider.autoDispose<BalanceResponse>((ref) async {
  final paymentService = ref.read(paymentServiceProvider);
  return await paymentService.getBalance();
});