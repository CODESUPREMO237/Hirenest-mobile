// Settings Page
// =====================================================
// lib/features/profile/presentation/pages/settings_page.dart
// =====================================================
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/settings_tile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.person,
                  title: 'Edit Profile',
                  onTap: () => context.push('/profile/edit'),
                ),
                const Divider(height: 1, thickness: 1, indent: AppSpacing.xl + 24, color: AppColors.borderLight),
                SettingsTile(
                  icon: Icons.verified_user,
                  title: 'Verification Badges',
                  subtitle: 'Get verified to build trust',
                  onTap: () => context.push('/verification'),
                ),
                const Divider(height: 1, thickness: 1, indent: AppSpacing.xl + 24, color: AppColors.borderLight),
                SettingsTile(
                  icon: Icons.star,
                  title: 'Subscription Plans',
                  subtitle: 'Boost listings & unlock features',
                  onTap: () => context.push('/subscription'),
                ),
                const Divider(height: 1, thickness: 1, indent: AppSpacing.xl + 24, color: AppColors.borderLight),
                SettingsTile(
                  icon: Icons.bookmark,
                  title: 'Saved Searches',
                  onTap: () => context.push('/saved-searches'),
                ),
                const Divider(height: 1, thickness: 1, indent: AppSpacing.xl + 24, color: AppColors.borderLight),
                SettingsTile(
                  icon: Icons.recommend,
                  title: 'Recommended Jobs',
                  subtitle: 'Smart matches based on your profile',
                  onTap: () => context.push('/recommended-jobs'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.gavel,
                  title: 'Terms & Privacy',
                  subtitle: 'Review and accept legal terms',
                  onTap: () => context.push('/legal-acceptance'),
                ),
                const Divider(height: 1, thickness: 1, indent: AppSpacing.xl + 24, color: AppColors.borderLight),
                SettingsTile(
                  icon: Icons.download,
                  title: 'Your Data & Privacy (GDPR)',
                  subtitle: 'Export data or delete account',
                  onTap: () => context.push('/gdpr'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: SettingsTile(
              icon: Icons.logout,
              iconColor: AppColors.error,
              title: 'Logout',
              titleColor: AppColors.error,
              onTap: () => _handleLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: const Text('Logout', style: TextStyle(color: AppColors.textPrimaryLight)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppColors.textSecondaryLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final logoutCtrl = ref.read(logoutControllerProvider);
      // 1. Clear backend state & invalidate providers
      await logoutCtrl.logout();
      
      if (context.mounted) {
        // 2. Navigate safely to login page
        context.go('/auth/login');
      }
      
      // 3. Sign out of Firebase LAST to avoid router rebuild loops
      await logoutCtrl.signOutFirebase();
    }
  }
}