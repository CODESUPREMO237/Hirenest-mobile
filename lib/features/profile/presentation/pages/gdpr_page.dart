// ============================================================================
// GDPR PAGE — Data Export & Account Deletion
// lib/features/profile/presentation/pages/gdpr_page.dart
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/account_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class GdprPage extends ConsumerStatefulWidget {
  const GdprPage({super.key});

  @override
  ConsumerState<GdprPage> createState() => _GdprPageState();
}

class _GdprPageState extends ConsumerState<GdprPage> {
  bool _exporting = false;
  bool _deleting = false;

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final repo = ref.read(accountRepositoryProvider);
      final data = await repo.exportMyData();

      // Save JSON to temp file and share
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hirenest_data_export.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'HireNest Data Export'),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Data exported successfully'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account Permanently?'),
        content: const Text(
          'This action cannot be undone. All your personal data will be anonymized, '
          'your listings will be deactivated, and you will be logged out.\n\n'
          'We recommend exporting your data first.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('DELETE PERMANENTLY'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      final repo = ref.read(accountRepositoryProvider);
      await repo.deleteMyAccount();

      if (!mounted) return;
      final logoutCtrl = ref.read(logoutControllerProvider);
      await logoutCtrl.logout();
      await logoutCtrl.signOutFirebase();
      
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Data & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Export Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.download_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    const Text('Export Your Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    'Download a copy of all your data including profile, jobs, products, orders, applications, and messages.',
                    style: TextStyle(color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _exportData,
                      icon: _exporting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download),
                      label: Text(_exporting ? 'Exporting...' : 'Export Data as JSON'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Delete Section
          Card(
            color: AppColors.error.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.delete_forever, color: AppColors.error, size: 28),
                    const SizedBox(width: 12),
                    Text('Delete Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.error)),
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    'Permanently delete your account. Your personal data will be anonymized and all listings deactivated. This cannot be undone.',
                    style: TextStyle(color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleting ? null : _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      icon: _deleting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_forever),
                      label: Text(_deleting ? 'Deleting...' : 'Delete My Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
