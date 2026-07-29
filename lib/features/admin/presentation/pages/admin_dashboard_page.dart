import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/repositories/admin_repository.dart';

// ============================================================================
// PROVIDERS
// ============================================================================
final adminServiceProvider = Provider<AdminService>((ref) {
  final dio = ref.watch(dioProvider);
  final authService = ref.watch(authServiceProvider);
  return AdminService(dio, authService);
});

final dashboardDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getDashboardOverview();
});

// ============================================================================
// ADMIN DASHBOARD SCREEN
// ============================================================================
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Gradient App Bar ──
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: const Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: AppColors.surfaceLight,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF635BFF),
                      Color(0xFF7C3AED),
                      Color(0xFF4F46E5),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceLight.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      right: 60,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceLight.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.surfaceLight),
                tooltip: 'Refresh',
                onPressed: () => ref.refresh(dashboardDataProvider),
              ),
              IconButton(
                icon: Icon(Icons.logout_rounded, color: AppColors.surfaceLight.withValues(alpha: 0.7)),
                tooltip: 'Logout',
                onPressed: () async {
                  await ref.read(authServiceProvider).logout();
                  if (context.mounted) context.go('/auth/login');
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Body ──
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section: Quick Actions
                _SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        title: 'Disputed\nOrders',
                        icon: Icons.gavel_rounded,
                        gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                        onTap: () => context.push('/admin/disputes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        title: 'User\nManagement',
                        icon: Icons.people_alt_rounded,
                        gradient: const [Color(0xFF635BFF), Color(0xFF4F46E5)],
                        onTap: () => context.push('/admin/users'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Section: System Overview
                _SectionHeader(title: 'System Overview'),
                const SizedBox(height: 12),
                const DashboardOverviewSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// ============================================================================
// QUICK ACTION CARD (gradient, icon, tap)
// ============================================================================
class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: AppSpacing.roundedLg,
      elevation: 2,
      shadowColor: gradient.first.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedLg,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.roundedLg,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.2),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Icon(icon, color: AppColors.surfaceLight, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.surfaceLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'View',
                    style: TextStyle(
                      color: AppColors.surfaceLight.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.surfaceLight.withValues(alpha: 0.8),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD OVERVIEW SECTION
// ============================================================================
class DashboardOverviewSection extends ConsumerWidget {
  const DashboardOverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);

    return dashboardData.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.error[50],
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(color: AppColors.error[200]),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(child: Text('Failed to load: $err', style: const TextStyle(color: AppColors.error))),
          ],
        ),
      ),
      data: (data) {
        final overview = data['overview'] ?? {};
        final recentUsers = (data['recentUsers'] as List?) ?? [];
        final usersByRole = (data['usersByRole'] as List?) ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat Cards Grid ──
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: '${overview['totalUsers'] ?? 0}',
                  subtitle: '${overview['activeUsers'] ?? 0} active',
                  icon: Icons.people_outline_rounded,
                  iconBgColor: const Color(0xFFEEEDFF),
                  iconColor: AppColors.primary,
                ),
                _StatCard(
                  title: 'Jobs',
                  value: '${overview['totalJobs'] ?? 0}',
                  subtitle: '${overview['activeJobs'] ?? 0} active',
                  icon: Icons.work_outline_rounded,
                  iconBgColor: const Color(0xFFE6FAF5),
                  iconColor: AppColors.success,
                ),
                _StatCard(
                  title: 'Products',
                  value: '${overview['totalProducts'] ?? 0}',
                  subtitle: '${overview['activeProducts'] ?? 0} active',
                  icon: Icons.shopping_bag_outlined,
                  iconBgColor: const Color(0xFFFFF8E7),
                  iconColor: const Color(0xFFD97706),
                ),
                _StatCard(
                  title: 'Applications',
                  value: '${overview['totalApplications'] ?? 0}',
                  subtitle: 'All time',
                  icon: Icons.description_outlined,
                  iconBgColor: const Color(0xFFF0E7FE),
                  iconColor: AppColors.accent,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Users By Role ──
            if (usersByRole.isNotEmpty) ...[
              const Text(
                'Users By Role',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.roundedMd,
                  boxShadow: AppSpacing.cardShadow,
                ),
                child: Column(
                  children: usersByRole.map<Widget>((role) {
                    final roleName = _formatRole(role['_id'] ?? 'unknown');
                    final count = role['count'] ?? 0;
                    final total = overview['totalUsers'] ?? 1;
                    final percentage = total > 0 ? (count / total) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _RoleDot(role: role['_id'] ?? 'unknown'),
                                  const SizedBox(width: 8),
                                  Text(roleName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              Text(
                                '$count users',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 6,
                              backgroundColor: AppColors.borderLight,
                              valueColor: AlwaysStoppedAnimation<Color>(_getRoleColor(role['_id'] ?? '')),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Recent Users ──
            if (recentUsers.isNotEmpty) ...[
              const Text(
                'Recent Users',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.roundedMd,
                  boxShadow: AppSpacing.cardShadow,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentUsers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = recentUsers[index];
                    final profile = user['profile'] ?? {};
                    final firstName = profile['firstName'] ?? '';
                    final lastName = profile['lastName'] ?? '';
                    final avatar = profile['avatar'];
                    final email = user['email'] ?? '';
                    final role = user['role'] ?? '';
                    final createdAt = user['createdAt'] ?? '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: _getRoleColor(role).withValues(alpha: 0.15),
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        child: avatar == null
                            ? Text(
                                firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: _getRoleColor(role),
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        '$firstName $lastName'.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      subtitle: Text(
                        email,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _RoleBadge(role: role),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(createdAt),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  static String _formatRole(String role) {
    return role.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  static Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.error;
      case 'employer':
        return AppColors.primary;
      case 'jobseeker':
      case 'job_seeker':
        return AppColors.success;
      default:
        return AppColors.borderLight;
    }
  }
}

// ============================================================================
// STAT CARD (clean, no overflow)
// ============================================================================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ROLE BADGE (compact pill)
// ============================================================================
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = DashboardOverviewSection._getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Text(
        DashboardOverviewSection._formatRole(role),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================================================
// ROLE DOT (for bar chart labels)
// ============================================================================
class _RoleDot extends StatelessWidget {
  final String role;
  const _RoleDot({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: DashboardOverviewSection._getRoleColor(role),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ============================================================================
// USERS MANAGEMENT PAGE
// ============================================================================
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String? _selectedRole;
  String? _selectedStatus;
  String _searchQuery = '';
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('User Management', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceLight,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: AppSpacing.roundedSm),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: AppColors.borderLight,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: const Text('All Roles', style: TextStyle(fontSize: 13)),
                            value: _selectedRole,
                            isExpanded: true,
                            items: [null, 'jobseeker', 'employer', 'admin']
                                .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role == null ? 'All Roles' : _formatRole(role), style: const TextStyle(fontSize: 13)),
                            ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedRole = value),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: const Text('All Status', style: TextStyle(fontSize: 13)),
                            value: _selectedStatus,
                            isExpanded: true,
                            items: [null, 'active', 'blocked']
                                .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status == null ? 'All Status' : '${status[0].toUpperCase()}${status.substring(1)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedStatus = value),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: ref.read(adminServiceProvider).getUsers(
                role: _selectedRole,
                status: _selectedStatus,
                search: _searchQuery.isEmpty ? null : _searchQuery,
                page: _currentPage,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final data = snapshot.data!;
                final users = data['users'] as List;
                final pagination = data['pagination'];

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _UserListTile(user: user);
                        },
                      ),
                    ),

                    // Pagination
                    _PaginationBar(
                      currentPage: pagination['page'],
                      totalPages: pagination['pages'],
                      onPageChanged: (page) => setState(() => _currentPage = page),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    return role.split('_').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}

class _UserListTile extends ConsumerWidget {
  final Map<String, dynamic> user;

  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlocked = user['isBlocked'] ?? false;
    final profile = user['profile'] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundImage: profile['avatar'] != null
              ? NetworkImage(profile['avatar'])
              : null,
          child: profile['avatar'] == null
              ? Text(
                  (profile['firstName'] ?? '?')[0],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                )
              : null,
        ),
        title: Text(
          '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim(),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? '', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            _RoleBadge(role: user['role'] ?? ''),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error[50],
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: const Text('Blocked', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            IconButton(
              icon: Icon(isBlocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 20),
              onPressed: () => _showBlockDialog(context, ref, user),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
              onPressed: () => _showDeleteDialog(context, ref, user),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    final isBlocked = user['isBlocked'] ?? false;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: Text(isBlocked ? 'Unblock User' : 'Block User'),
        content: isBlocked
            ? const Text('Are you sure you want to unblock this user?')
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to block this user?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(borderRadius: AppSpacing.roundedSm),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? AppColors.success : AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            ),
            onPressed: () async {
              try {
                await ref.read(adminServiceProvider).toggleUserBlock(
                  user['_id'],
                  reason: isBlocked ? null : reasonController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isBlocked ? 'User unblocked' : 'User blocked')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: const Text('Delete User'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
            ),
            onPressed: () async {
              try {
                await ref.read(adminServiceProvider).deleteUser(user['_id']);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.surfaceLight)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAGINATION BAR
// ============================================================================
class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Text(
              'Page $currentPage of $totalPages',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}
