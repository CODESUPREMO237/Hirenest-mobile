// lib/features/company/presentation/pages/manage_admins_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
    setState(() => _isSearching = true);
    try {
      await ref.read(searchUsersProvider(query).future);
    } catch (e, stack) {
      AppLogger.error('User search failed', error: e, stackTrace: stack);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search error: $e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addAdmin(String userId, String companyId) async {
    try {
      await ref.read(adminActionsProvider.notifier).addAdmin(companyId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin added'), backgroundColor: AppColors.success));
        _searchController.clear();
        ref.invalidate(myCompanyProvider);
      }
    } catch (e, stack) {
      AppLogger.error('Failed to add admin', error: e, stackTrace: stack);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  void _removeAdmin(String adminId, String companyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Remove Admin'),
        content: const Text('Are you sure you want to remove this administrator?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminActionsProvider.notifier).removeAdmin(companyId, adminId);
      if (mounted) ref.invalidate(myCompanyProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(myCompanyProvider);
    final adminState = ref.watch(adminActionsProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          'Manage Admins',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => CustomErrorWidget(
          message: 'Failed to load company admins',
          onRetry: () => ref.invalidate(myCompanyProvider),
        ),
        data: (company) {
          final isCreator = currentUser?.id == company.createdBy;

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceLight,
            onRefresh: () async => ref.invalidate(myCompanyProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _buildHeader(context, company.name),
                  const SizedBox(height: AppSpacing.xl),
                  if (isCreator) ...[
                    _buildAddAdminSection(context, company.id),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  _buildAdminsList(context, company, isCreator, adminState),
                  const SizedBox(height: AppSpacing.xl),
                  _buildInfoBox(context, isCreator),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String companyName) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppSpacing.roundedLg,
          ),
          child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 32),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Management',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Control access for $companyName',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddAdminSection(BuildContext context, String companyId) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New Admin',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'User email...',
                    hintStyle: const TextStyle(color: AppColors.textMutedLight),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd, borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  ),
                  onSubmitted: (_) => _searchUsers(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _isSearching ? null : _searchUsers,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                ),
                child: _isSearching
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSearchResults(companyId),
        ],
      ),
    );
  }

  Widget _buildSearchResults(String companyId) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return const SizedBox();

    return Consumer(builder: (context, ref, child) {
      return ref.watch(searchUsersProvider(query)).when(
        data: (users) {
          if (users.isEmpty) return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text('No users found', style: TextStyle(color: AppColors.textMutedLight)));
          return Column(
            children: users.map((u) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(u.email, style: const TextStyle(color: AppColors.textSecondaryLight)),
              trailing: TextButton(
                onPressed: () => _addAdmin(u.id, companyId),
                child: const Text('Add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            )).toList(),
          );
        },
        loading: () => const Padding(padding: EdgeInsets.only(top: 8.0), child: LinearProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Error searching users', style: TextStyle(color: AppColors.error.withValues(alpha: 0.8), fontSize: 12))),
      );
    });
  }

  Widget _buildAdminsList(BuildContext context, CompanyModel company, bool isCreator, AdminActionsState adminState) {
    final admins = company.admins;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Administrators (${admins.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.borderLight),
          if (admins.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: Text('No admins found', style: TextStyle(color: AppColors.textMutedLight)))),
          ...admins.map((user) {
            final isOwner = user.id == company.createdBy;
            final isRemoving = adminState.isLoading && adminState.currentAdminId == user.id;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: user.profile?.avatar != null ? NetworkImage(user.profile!.avatar!) : null,
                child: user.profile?.avatar == null ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)) : null,
              ),
              title: Text(isOwner ? '${user.fullName} (Owner)' : user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(user.email, style: const TextStyle(color: AppColors.textSecondaryLight)),
              trailing: isOwner
                  ? const Icon(Icons.verified, color: AppColors.primary)
                  : (isCreator
                      ? (isRemoving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                          : IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                              onPressed: () => _removeAdmin(user.id, company.id),
                            ))
                      : null),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, bool isCreator) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              isCreator
                  ? 'As the company creator, you can add or remove administrators.'
                  : 'Only the company creator can add or remove administrators.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}