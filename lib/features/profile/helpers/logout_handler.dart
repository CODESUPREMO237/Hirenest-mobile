// ============================================================================
// logout_handler.dart - Fixed Logout Handler
// lib/features/profile/helpers/logout_handler.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../applications/presentation/providers/applications_provider.dart';
import '../../chat/presentation/providers/chats_provider.dart';
import '../presentation/providers/profile_provider.dart';

/// ✅ Complete logout handler that clears everything
Future<void> handleLogout(
    BuildContext context,
    WidgetRef ref, {
      bool showConfirmation = true,
    }) async {
  // Optional: Show confirmation dialog
  if (showConfirmation) {
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
  }

  try {
    debugPrint('');
    debugPrint('╔════════════════════════════════════════════════════╗');
    debugPrint('║         STARTING COMPLETE LOGOUT PROCESS          ║');
    debugPrint('╚════════════════════════════════════════════════════╝');
    debugPrint('');

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Logging out...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ✅ Step 1: Invalidate ALL providers BEFORE logout
    // This prevents the "Cannot use ref after disposal" error
    debugPrint('🔄 Step 1: Invalidating all providers...');

    try {
      // Invalidate auth providers
      ref.invalidate(authStateProvider);
      ref.invalidate(isAuthenticatedProvider);

      // Invalidate user data providers
      ref.invalidate(userRoleProvider);
      ref.invalidate(myApplicationsProvider);
      ref.invalidate(applicationStatsProvider);
      ref.invalidate(profileProvider);

      // Invalidate other providers
      ref.invalidate(chatsProvider);
      // ref.invalidate(jobsProvider);
      // ref.invalidate(marketplaceProvider);
      // Add more as needed

      debugPrint('✅ Step 1: All providers invalidated');
    } catch (e) {
      debugPrint('⚠️ Step 1: Some providers failed to invalidate: $e');
      // Continue anyway - not critical
    }

    // ✅ Step 2: Call AuthService logout
    debugPrint('🚪 Step 2: Calling AuthService.logout()...');
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    debugPrint('✅ Step 2: AuthService logout complete');

    // ✅ Step 3: Wait for cleanup to propagate
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('✅ Step 3: Cleanup propagated');

    // ✅ Step 4: Close loading dialog if still mounted
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // ✅ Step 5: Navigate to login/welcome screen
    debugPrint('🔀 Step 5: Navigating to login screen...');
    if (context.mounted) {
      // Clear all navigation stack and go to login
      context.go('/auth/login');
    }
    debugPrint('✅ Step 5: Navigation complete');

    // ✅ Step 6: Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }

    debugPrint('');
    debugPrint('╔════════════════════════════════════════════════════╗');
    debugPrint('║           LOGOUT COMPLETED SUCCESSFULLY           ║');
    debugPrint('╚════════════════════════════════════════════════════╝');
    debugPrint('');

  } catch (e, stackTrace) {
    debugPrint('❌ Logout error: $e');
    debugPrint('   Stack trace: $stackTrace');

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: AppColors.white,
            onPressed: () => handleLogout(context, ref, showConfirmation: false),
          ),
        ),
      );
    }
  }
}

/// Force logout without confirmation (useful for error states)
Future<void> forceLogout(BuildContext context, WidgetRef ref) async {
  await handleLogout(context, ref, showConfirmation: false);
}

/// Emergency logout - minimal cleanup, forces navigation
/// Use when normal logout fails or when you need immediate logout
Future<void> emergencyLogout(BuildContext context, WidgetRef ref) async {
  try {
    debugPrint('🚨 Emergency logout initiated');

    // Try to logout from AuthService
    try {
      final authService = ref.read(authServiceProvider);
      await authService.logout();
    } catch (e) {
      debugPrint('⚠️ AuthService logout failed during emergency: $e');
    }

    // Force navigation regardless of errors
    if (context.mounted) {
      context.go('/auth/login');
    }

    debugPrint('✅ Emergency logout complete');
  } catch (e) {
    debugPrint('❌ Emergency logout error: $e');
    // Still try to navigate
    if (context.mounted) {
      context.go('/auth/login');
    }
  }
}