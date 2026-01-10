// Settings Page
// =====================================================
// lib/features/profile/presentation/pages/settings_page.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../widgets/settings_tile.dart';
import '../../../../core/services/notification_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.read(notificationServiceProvider);

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
          
          // ✅ NOTIFICATION TEST SECTION
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Developer Tools',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          // Test Notification Button
          SettingsTile(
            icon: Icons.send,
            title: 'Send Test Notification',
            subtitle: 'Test local notifications',
            onTap: () async {
              await notificationService.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Test notification sent! Check your notifications.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          
          // Get FCM Token Button
          SettingsTile(
            icon: Icons.key,
            title: 'Copy FCM Token',
            subtitle: 'For testing from Firebase Console',
            onTap: () async {
              final token = await notificationService.getToken();
              if (token != null) {
                await Clipboard.setData(ClipboardData(text: token));
                print('🔑 FCM TOKEN: $token');
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ Token copied to clipboard! Check debug console.'),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Failed to get FCM token'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
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