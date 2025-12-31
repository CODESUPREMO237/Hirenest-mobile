// ==================== 7. ROUTE GUARD ====================
// lib/core/router/admin_guard.dart

// ==================== 7. ROUTE GUARD ====================
// lib/core/routing/admin_guard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';


class AdminGuard extends ConsumerWidget {
  final Widget child;

  const AdminGuard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Redirect to login
          Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Check if user is admin (you'll need to fetch this from storage or user data)
        return FutureBuilder<String?>(
          future: ref.read(authServiceProvider).getBackendToken().then((_) async {
            // Get user role from storage
            final storage = const FlutterSecureStorage();
            return await storage.read(key: 'user_role');
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final role = snapshot.data;
            if (role != 'admin') {
              Future.microtask(() => Navigator.pushReplacementNamed(context, '/'));
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, size: 64, color: Colors.red),
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
      error: (_, __) {
        Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
