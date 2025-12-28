
// =====================================================
// PAGES
// lib/features/home/presentation/pages/guest_dashboard.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class GuestDashboard extends ConsumerWidget {
  const GuestDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse as Guest'),
        actions: [
          TextButton(
            onPressed: () => context.go('/auth/login'),
            child: const Text('Login'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Limited Access',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign up to unlock all features',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildLimit('Jobs', '10 per day'),
                    const Divider(),
                    _buildLimit('Products', '20 per day'),
                    const Divider(),
                    _buildLimit('Chat', 'Disabled'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/auth/register'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimit(String feature, String limit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(feature, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(limit, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
