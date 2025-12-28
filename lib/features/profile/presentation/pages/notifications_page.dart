// lib/features/profile/presentation/pages/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/activity_provider.dart';
import '../providers/profile_provider.dart';
import '../../data/models/notification_preferences_model.dart';
import '../../data/repositories/profile_repository.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final prefs = profile.notificationPreferences;

          return ListView(
            children: [
              // Notification Settings Section
              _buildSectionHeader(context, 'Notification Settings'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active),
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive push notifications on this device'),
                      value: prefs?.push ?? true,
                      onChanged: (value) async => await _updatePreference(ref, 'push', value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.email_outlined),
                      title: const Text('Email Notifications'),
                      subtitle: const Text('Receive notifications via email'),
                      value: prefs?.email ?? true,
                      onChanged: (value) async => await _updatePreference(ref, 'email', value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.sms_outlined),
                      title: const Text('SMS Notifications'),
                      subtitle: const Text('Receive notifications via SMS'),
                      value: prefs?.sms ?? false,
                      onChanged: (value) async => await _updatePreference(ref, 'sms', value),
                    ),
                  ],
                ),
              ),

              // Notification Categories
              _buildSectionHeader(context, 'Categories'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.work_outline),
                      title: const Text('Job Alerts'),
                      subtitle: const Text('New jobs matching your profile'),
                      value: prefs?.jobAlerts ?? true,
                      onChanged: (value) async => await _updatePreference(ref, 'jobAlerts', value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.chat_bubble_outline),
                      title: const Text('Chat Messages'),
                      subtitle: const Text('New messages from buyers/sellers'),
                      value: prefs?.chatMessages ?? true,
                      onChanged: (value) async => await _updatePreference(ref, 'chatMessages', value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.mail_outline),
                      title: const Text('Marketing Emails'),
                      subtitle: const Text('Promotional offers and updates'),
                      value: prefs?.marketingEmails ?? false,
                      onChanged: (value) async => await _updatePreference(ref, 'marketingEmails', value),
                    ),
                  ],
                ),
              ),

              // Recent Notifications Section
              _buildSectionHeader(context, 'Recent'),
              _buildNotificationsList(ref),
              const SizedBox(height: 32),
            ],
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
                onPressed: () => ref.refresh(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(WidgetRef ref) {
    final activities = ref.watch(recentActivityProvider);

    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No recent activity found')),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = activities[index];

        final notification = _NotificationItem(
          type: item['type'],
          icon: item['icon'],
          iconColor: item['color'],
          title: item['title'],
          message: item['message'],
          time: item['time'],
          isRead: true,
        );

        return Dismissible(
          key: Key('notification_${notification.time.millisecondsSinceEpoch}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear Notification'),
                content: const Text('Are you sure you want to remove this alert?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
          onDismissed: (direction) async {
            try {
              await ref.read(profileRepositoryProvider).clearNotification(notification.time);
              ref.invalidate(recentActivityProvider);
            } catch (e) {
              ref.invalidate(recentActivityProvider);
            }
          },
          child: _buildNotificationCard(ref.context, notification),
        );
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context, _NotificationItem notification) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: notification.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(notification.icon, color: notification.iconColor),
        ),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.time),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () {
          switch (notification.type) {
            case 'job':
              context.push('/jobs');
              break;
            case 'application':
              context.push('/applications');
              break;
            case 'sale':
              context.push('/marketplace/my-products');
              break;
            default:
              context.go('/');
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Future<void> _updatePreference(WidgetRef ref, String key, bool value) async {
    try {
      final profile = ref.read(profileProvider).value;
      if (profile == null) return;

      final currentPrefs = profile.notificationPreferences ?? NotificationPreferences(
        email: true, push: true, sms: false, jobAlerts: true, chatMessages: true, marketingEmails: false,
      );

      NotificationPreferences updatedPrefs;
      switch (key) {
        case 'push': updatedPrefs = currentPrefs.copyWith(push: value); break;
        case 'email': updatedPrefs = currentPrefs.copyWith(email: value); break;
        case 'sms': updatedPrefs = currentPrefs.copyWith(sms: value); break;
        case 'jobAlerts': updatedPrefs = currentPrefs.copyWith(jobAlerts: value); break;
        case 'chatMessages': updatedPrefs = currentPrefs.copyWith(chatMessages: value); break;
        case 'marketingEmails': updatedPrefs = currentPrefs.copyWith(marketingEmails: value); break;
        default: return;
      }

      await ref.read(profileRepositoryProvider).updateNotificationPreferences(updatedPrefs);
      ref.invalidate(profileProvider);
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    }
  }
}

class _NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final String type;

  _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });
}