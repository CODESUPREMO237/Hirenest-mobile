// Settings Page
// =====================================================
// lib/features/profile/presentation/pages/settings_page.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SettingsTile(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () => context.push('/profile/edit'),
          ),
          SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.lock,
            title: 'Privacy',
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {},
          ),
          SettingsTile(
            icon: Icons.info,
            title: 'About',
            onTap: () {},
          ),
          const Divider(),
          SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        context.go('/auth/login');
      }
    }
  }
}