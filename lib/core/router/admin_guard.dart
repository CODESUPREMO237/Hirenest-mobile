// ==================== 7. ROUTE GUARD ====================
// lib/core/routing/admin_guard.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/auth_service.dart';

class AdminGuard extends ConsumerWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Redirect to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/auth/login');
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Check if user is admin via stored userData
        return FutureBuilder<bool>(
          future: ref.read(authServiceProvider).getBackendToken().then((_) async {
            final storage = const FlutterSecureStorage();
            final userDataStr = await storage.read(key: 'user_data');
            if (userDataStr != null) {
              try {
                final userData = jsonDecode(userDataStr);
                return userData['isAdmin'] == true;
              } catch (e) {
                return false;
              }
            }
            return false;
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final isAdmin = snapshot.data ?? false;
            if (!isAdmin) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/');
                }
              });
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      const Text('Access Denied', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('You do not have permission to access this area.'),
                    ],
                  ),
                ),
              );
            }

            return child;
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/auth/login');
          }
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
