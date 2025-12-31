

// ==================== 3. ADMIN DASHBOARD SCREEN ====================
// lib/features/admin/presentation/pages/admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/repositories/admin_repository.dart';

// Provider
final adminServiceProvider = Provider<AdminService>((ref) {
  final dio = ref.watch(dioProvider);
  final authService = ref.watch(authServiceProvider);
  return AdminService(dio, authService);
});

final dashboardDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getDashboardOverview();
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navItems = [
    NavigationItem(icon: Icons.dashboard, label: 'Dashboard'),
    NavigationItem(icon: Icons.people, label: 'Users'),
    NavigationItem(icon: Icons.work, label: 'Jobs'),
    NavigationItem(icon: Icons.shopping_bag, label: 'Products'),
    NavigationItem(icon: Icons.report, label: 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(dashboardDataProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.white,
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? Colors.deepPurple : Colors.grey[600],
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.deepPurple : Colors.grey[800],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.deepPurple.withOpacity(0.1),
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),

          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardOverviewTab();
      case 1:
        return const UsersManagementTab();
      case 2:
        return const JobsManagementTab();
      case 3:
        return const ProductsManagementTab();
      case 4:
        return const ReportsTab();
      default:
        return const DashboardOverviewTab();
    }
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  NavigationItem({required this.icon, required this.label});
}

// ==================== 4. DASHBOARD OVERVIEW TAB ====================
class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);

    return dashboardData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (data) {
        final overview = data['overview'];
        final usersByRole = data['usersByRole'] as List;
        final recentUsers = data['recentUsers'] as List;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    title: 'Total Users',
                    value: '${overview['totalUsers']}',
                    subtitle: '${overview['activeUsers']} active',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Jobs',
                    value: '${overview['totalJobs']}',
                    subtitle: '${overview['activeJobs']} active',
                    icon: Icons.work,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Products',
                    value: '${overview['totalProducts']}',
                    subtitle: '${overview['activeProducts']} active',
                    icon: Icons.shopping_bag,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Applications',
                    value: '${overview['totalApplications']}',
                    subtitle: 'All time',
                    icon: Icons.description,
                    color: Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Users by Role
              Text(
                'Users by Role',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: usersByRole.map((role) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(role['_id']),
                          child: Text(
                            '${role['count']}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(_formatRole(role['_id'])),
                        trailing: Text(
                          '${role['count']} users',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Recent Users
              Text(
                'Recent Users',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Joined')),
                  ],
                  rows: recentUsers.map((user) {
                    return DataRow(cells: [
                      DataCell(Text('${user['profile']['firstName']} ${user['profile']['lastName']}')),
                      DataCell(Text(user['email'])),
                      DataCell(_RoleBadge(role: user['role'])),
                      DataCell(Text(_formatDate(user['createdAt']))),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'employer':
        return Colors.blue;
      case 'job_seeker':
        return Colors.green;
      case 'seller':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    return role.split('_').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 5. USERS MANAGEMENT TAB ====================
class UsersManagementTab extends ConsumerStatefulWidget {
  const UsersManagementTab({Key? key}) : super(key: key);

  @override
  ConsumerState<UsersManagementTab> createState() => _UsersManagementTabState();
}

class _UsersManagementTabState extends ConsumerState<UsersManagementTab> {
  String? _selectedRole;
  String? _selectedStatus;
  String _searchQuery = '';
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                hint: const Text('Role'),
                value: _selectedRole,
                items: ['job_seeker', 'employer', 'seller', 'admin']
                    .map((role) => DropdownMenuItem(
                  value: role,
                  child: Text(_formatRole(role)),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                hint: const Text('Status'),
                value: _selectedStatus,
                items: ['active', 'blocked']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status[0].toUpperCase() + status.substring(1)),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedStatus = value),
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
                return const Center(child: CircularProgressIndicator());
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user['profile']['avatar'] != null
              ? NetworkImage(user['profile']['avatar'])
              : null,
          child: user['profile']['avatar'] == null
              ? Text(user['profile']['firstName'][0])
              : null,
        ),
        title: Text('${user['profile']['firstName']} ${user['profile']['lastName']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email']),
            _RoleBadge(role: user['role']),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBlocked)
              const Chip(
                label: Text('Blocked', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.red,
              ),
            IconButton(
              icon: Icon(isBlocked ? Icons.lock_open : Icons.block),
              onPressed: () => _showBlockDialog(context, ref, user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
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
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
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
        title: const Text('Delete User'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ==================== 6. SHARED WIDGETS ====================
class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = _getRoleColor(role);
    return Chip(
      label: Text(
        _formatRole(role),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'employer':
        return Colors.blue;
      case 'job_seeker':
        return Colors.green;
      case 'seller':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    return role.split('_').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}

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
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          Text('Page $currentPage of $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}

// ==================== PLACEHOLDER TABS (implement similarly) ====================
class JobsManagementTab extends StatelessWidget {
  const JobsManagementTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Jobs Management - Coming Soon'));
  }
}

class ProductsManagementTab extends StatelessWidget {
  const ProductsManagementTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Products Management - Coming Soon'));
  }
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Reports - Coming Soon'));
  }
}

