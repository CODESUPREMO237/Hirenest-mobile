// lib/features/profile/presentation/pages/notifications_page.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.textPrimaryLight),
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
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              // Notification Settings Section
              _buildSectionHeader(context, 'Notification Settings'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppSpacing.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      context,
                      icon: Icons.notifications_active,
                      title: 'Push Notifications',
                      subtitle: 'Receive push notifications on this device',
                      value: prefs?.push ?? true,
                      onChanged: (value) async => await _updatePreference(ref, 'push', value),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    _buildSwitchTile(
                      context,
                      icon: Icons.email_outlined,
                      title: 'Email Notifications',
                      subtitle: 'Receive notifications via email',
                      value: prefs?.email ?? true,
                      onChanged: (value) async => await _updatePreference(ref, 'email', value),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    _buildSwitchTile(
                      context,
                      icon: Icons.sms_outlined,
                      title: 'SMS Notifications',
                      subtitle: 'Receive notifications via SMS',
                      value: prefs?.sms ?? false,
                      onChanged: (value) async => await _updatePreference(ref, 'sms', value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              // Notification Categories
              _buildSectionHeader(context, 'Categories'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: AppSpacing.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      context,
                      icon: Icons.work_outline,
                      title: 'Job Alerts',
                      subtitle: 'New jobs matching your profile',
                      value: prefs?.jobAlerts ?? true,
                      onChanged: (value) async => await _updatePreference(ref, 'jobAlerts', value),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    _buildSwitchTile(
                      context,
                      icon: Icons.chat_bubble_outline,
                      title: 'Chat Messages',
                      subtitle: 'New messages from buyers/sellers',
                      value: prefs?.chatMessages ?? true,
                      onChanged: (value) async => await _updatePreference(ref, 'chatMessages', value),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    _buildSwitchTile(
                      context,
                      icon: Icons.mail_outline,
                      title: 'Marketing Emails',
                      subtitle: 'Promotional offers and updates',
                      value: prefs?.marketingEmails ?? false,
                      onChanged: (value) async => await _updatePreference(ref, 'marketingEmails', value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              // Recent Notifications Section
              _buildSectionHeader(context, 'Recent'),
              _buildNotificationsList(ref),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.lg),
              Text('Error: $error', style: const TextStyle(color: AppColors.textSecondaryLight)),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => ref.refresh(profileProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
      value: value,
      activeThumbColor: AppColors.primary,
      onChanged: onChanged,
    );
  }

  Widget _buildNotificationsList(WidgetRef ref) {
    final activities = ref.watch(recentActivityProvider);

    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: Text(
            'No recent activity found',
            style: Theme.of(ref.context).textTheme.bodyLarge?.copyWith(color: AppColors.textMutedLight),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
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
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: AppSpacing.roundedLg,
            ),
            child: const Icon(Icons.delete, color: AppColors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.surfaceLight,
                title: const Text('Clear Notification', style: TextStyle(color: AppColors.textPrimaryLight)),
                content: const Text('Are you sure you want to remove this alert?', style: TextStyle(color: AppColors.textSecondaryLight)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                  ),
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
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.surfaceLight : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: AppSpacing.roundedLg,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppSpacing.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: notification.iconColor.withValues(alpha: 0.1),
            borderRadius: AppSpacing.roundedMd,
          ),
          child: Icon(notification.icon, color: notification.iconColor),
        ),
        title: Text(
          notification.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              notification.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              timeago.format(notification.time),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMutedLight,
                  ),
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
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textMutedLight,
              letterSpacing: 1.2,
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