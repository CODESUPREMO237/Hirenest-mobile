


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/payment_service.dart';
import '../../../applications/presentation/providers/applications_provider.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
// import '../../../jobs/presentation/providers/jobs_provider.dart'; // Adjust this path to your jobs provider

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
            onPressed: () {
              context.push('/profile/settings');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            // Refresh both profile and balance
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
                      // Avatar
                      Stack(
                        children: [
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
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.camera_alt,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                onPressed: () {
                                  // Upload avatar
                                },
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
                    ],
                  ),
                ),

                // Balance Card (for sellers)
                if (profile.role == 'jobseeker' || profile.role == 'employer')
                  balanceAsync.when(
                    data: (balance) => InkWell(
                      onTap: () => context.push('/profile/balance'),
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[700]!,
                              Colors.green[500]!,
                            ],
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
                                const Icon(
                                  Icons.account_balance_wallet,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
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
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (error, _) => const SizedBox.shrink(),
                  ),

                // Profile Stats
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
                          ref.watch(applicationStatsProvider).maybeWhen(data: (stats) => '${stats['total'] ?? 0}', orElse: () => '0'),
                          'Applications',
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          Icons.star_outline,
                          profile.marketplaceStats?.sellerRating?.average.toStringAsFixed(1) ?? '0.0',
                          'Rating',
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
        ),
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
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
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
      case 'guest':
        return 'Guest';
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

              // Show loading indicator
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              try {
                // Use the centralized logout controller
                await ref.read(logoutControllerProvider).logout();

                if (context.mounted) {
                  // Dismiss loading
                  Navigator.pop(context);
                  // Navigate to login
                  context.go('/auth/login');
                }
              } catch (e) {
                if (context.mounted) {
                  // Dismiss loading
                  Navigator.pop(context);
                  // Show error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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

// Balance provider
final balanceProvider = FutureProvider.autoDispose<BalanceResponse>((ref) async {
  final paymentService = ref.read(paymentServiceProvider);
  return await paymentService.getBalance();
});