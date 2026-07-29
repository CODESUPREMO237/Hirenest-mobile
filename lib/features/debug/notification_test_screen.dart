// lib/features/debug/notification_test_screen.dart
// OPTIONAL: Use this screen to test notifications

import 'package:flutter/material.dart';
import '../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';

class NotificationTestScreen extends ConsumerWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.read(notificationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Local Notification
            ElevatedButton.icon(
              onPressed: () async {
                await notificationService.showTestNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Send Test Notification'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 16),

            // Get FCM Token
            ElevatedButton.icon(
              onPressed: () async {
                final token = await notificationService.getToken();
                if (token != null) {
                  await Clipboard.setData(ClipboardData(text: token));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FCM Token copied to clipboard!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                  debugPrint('FCM Token: $token');
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to get FCM token'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.key),
              label: const Text('Get & Copy FCM Token'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // Subscribe to Test Topic
            ElevatedButton.icon(
              onPressed: () async {
                await notificationService.subscribeToTopic('test');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscribed to "test" topic'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add_alert),
              label: const Text('Subscribe to "test" Topic'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 16),

            const Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Click "Send Test Notification" to verify local notifications work\n\n'
              '2. Click "Get & Copy FCM Token" to copy your device token\n\n'
              '3. Use the token to send a test notification from Firebase Console:\n'
              '   - Go to Firebase Console > Cloud Messaging\n'
              '   - Click "Send your first message"\n'
              '   - Enter a title and message\n'
              '   - Click "Send test message"\n'
              '   - Paste your token and click "Test"\n\n'
              '4. You should receive the notification on your device',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}