// lib/features/company/presentation/pages/manage_admins_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../providers/company_provider.dart';
import '../providers/admin_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/company_model.dart';

class ManageAdminsPage extends ConsumerStatefulWidget {
  const ManageAdminsPage({super.key});

  @override
  ConsumerState<ManageAdminsPage> createState() => _ManageAdminsPageState();
}

class _ManageAdminsPageState extends ConsumerState<ManageAdminsPage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      AppLogger.warning('Search attempted with empty query');
      return;
    }

    AppLogger.debug('Searching users with query: $query');
    setState(() => _isSearching = true);

    try {
      await ref.read(searchUsersProvider(query).future);
      AppLogger.info('User search completed');
    } catch (e, stack) {
      AppLogger.error('User search failed', error: e, stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addAdmin(String userId, String companyId) async {
    AppLogger.info('Adding admin: $userId to company: $companyId');

    try {
      await ref.read(adminActionsProvider.notifier).addAdmin(companyId, userId);

      if (mounted) {
        AppLogger.info('Admin added successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin added'),
            backgroundColor: Colors.green,
          ),
        );
        _searchController.clear();
        ref.invalidate(myCompanyProvider);
      }
    } catch (e, stack) {
      AppLogger.error('Failed to add admin', error: e, stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeAdmin(String adminId, String companyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: const Text('Are you sure you want to remove this administrator?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(adminActionsProvider.notifier).removeAdmin(companyId, adminId);
      if (mounted) ref.invalidate(myCompanyProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(myCompanyProvider);
    final adminState = ref.watch(adminActionsProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Admins'), elevation: 0),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load company admins',
          onRetry: () => ref.invalidate(myCompanyProvider),
        ),
        data: (company) {
          if (company == null) return const Center(child: Text('Company not found'));

          final isCreator = currentUser?.id == company.createdBy;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myCompanyProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(company.name),
                  const SizedBox(height: 24),
                  if (isCreator) ...[
                    _buildAddAdminSection(company.id),
                    const SizedBox(height: 24),
                  ],
                  _buildAdminsList(company, isCreator, adminState),
                  const SizedBox(height: 24),
                  _buildInfoBox(isCreator),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String companyName) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.shield, color: Colors.blue.shade700, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Admin Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Control access for $companyName', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddAdminSection(String companyId) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                        hintText: 'User email...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    onSubmitted: (_) => _searchUsers(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSearching ? null : _searchUsers,
                  icon: _isSearching
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSearchResults(companyId),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(String companyId) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return const SizedBox();

    return Consumer(builder: (context, ref, child) {
      return ref.watch(searchUsersProvider(query)).when(
        data: (users) {
          if (users.isEmpty) return const Text('No users found', style: TextStyle(color: Colors.grey));
          return Column(
            children: users.map((u) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(u.fullName),
              subtitle: Text(u.email),
              trailing: TextButton(onPressed: () => _addAdmin(u.id, companyId), child: const Text('Add')),
            )).toList(),
          );
        },
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('Error searching users', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
      );
    });
  }

  Widget _buildAdminsList(CompanyModel company, bool isCreator, AdminActionsState adminState) {
    final admins = company.admins;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Administrators (${admins.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            if (admins.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No admins found'))),
            ...admins.map((user) {
              final isOwner = user.id == company.createdBy;
              final isRemoving = adminState.isLoading && adminState.currentAdminId == user.id;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: user.profile?.avatar != null ? NetworkImage(user.profile!.avatar!) : null,
                  child: user.profile?.avatar == null ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?') : null,
                ),
                title: Text(isOwner ? '${user.fullName} (Owner)' : user.fullName),
                subtitle: Text(user.email),
                trailing: isOwner
                    ? const Icon(Icons.verified, color: Colors.blue)
                    : (isCreator
                    ? (isRemoving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeAdmin(user.id, company.id),
                ))
                    : null),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(bool isCreator) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCreator
                  ? 'As the company creator, you can add or remove administrators.'
                  : 'Only the company creator can add or remove administrators.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}