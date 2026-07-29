// =====================================================
// AUTH PROVIDER WITH CACHE-FIRST STRATEGY
// lib/features/auth/presentation/providers/auth_provider.dart
// =====================================================
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/auth_service.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../home/presentation/pages/main_page.dart';
import '../../../profile/presentation/providers/balance_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

// Import marketplace providers
import '../../../marketplace/presentation/providers/paginated_products_notifier.dart';
import '../../../marketplace/presentation/providers/my_products_provider.dart';
import '../../../marketplace/presentation/providers/order_details_provider.dart';

// Import applications provider (with alias to avoid conflict)
import '../../../applications/presentation/providers/applications_provider.dart'
as app_providers;

// =====================================================
// CORE AUTH PROVIDERS
// =====================================================

final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// ✅ FIXED: Cache-first user provider that avoids unnecessary API calls
final currentUserProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (firebaseUser) async {
      if (firebaseUser == null) {
        debugPrint('ℹ️ [currentUserProvider] No Firebase user');
        return null;
      }

      try {
        final authService = ref.read(authServiceProvider);

        // ✅ CACHE-FIRST: Try to get cached user data first
        debugPrint('📦 [currentUserProvider] Checking cache...');
        final cachedData = await authService.getCachedUserData();

        if (cachedData != null) {
          debugPrint('✅ [currentUserProvider] Using cached data for: ${cachedData['email']}');
          return UserModel.fromJson(cachedData);
        }

        // ✅ FALLBACK: Only fetch from server if no cache
        debugPrint('📡 [currentUserProvider] No cache, fetching from server...');
        final user = await ref.read(authRepositoryProvider).getCurrentUser();
        debugPrint('✅ [currentUserProvider] Server fetch successful: ${user.email}');
        return user;

      } catch (e) {
        debugPrint('❌ [currentUserProvider] Error: $e');

        // ✅ ULTIMATE FALLBACK: Try cache one more time
        try {
          final authService = ref.read(authServiceProvider);
          final cachedData = await authService.getCachedUserData();

          if (cachedData != null) {
            debugPrint('⚠️ [currentUserProvider] Using cached data as fallback after error');
            return UserModel.fromJson(cachedData);
          }
        } catch (cacheError) {
          debugPrint('❌ [currentUserProvider] Cache fallback also failed: $cacheError');
        }

        // If everything fails, rethrow
        rethrow;
      }
    },
    loading: () {
      debugPrint('⏳ [currentUserProvider] Auth state loading...');
      return null;
    },
    error: (error, stack) {
      debugPrint('❌ [currentUserProvider] Auth state error: $error');
      return null;
    },
  );
});

// =====================================================
// MANUAL REFRESH PROVIDER
// =====================================================

/// Use this when you need to force refresh user data from server
final refreshUserProvider = Provider.autoDispose((ref) {
  return () async {
    debugPrint('🔄 [refreshUserProvider] Manually refreshing user data...');
    ref.invalidate(currentUserProvider);
    await ref.read(currentUserProvider.future);
  };
});

// =====================================================
// LOGOUT MANAGEMENT PROVIDER
// =====================================================

/// Centralized logout provider that handles sign out and state cleanup
final logoutControllerProvider = Provider<LogoutController>((ref) {
  return LogoutController(ref);
});

class LogoutController {
  final Ref ref;

  LogoutController(this.ref);

  /// Performs complete logout: clears backend state, invalidates providers,
  /// then signs out Firebase LAST to avoid router rebuild during cleanup.
  Future<void> logout() async {
    try {
      debugPrint('🚪 [LogoutController] Starting logout...');

      final authService = ref.read(authServiceProvider);

      // 1. Clear backend tokens & cached user data from storage FIRST
      //    This does NOT trigger the router (no Firebase signOut yet)
      await authService.clearAuthData();
      debugPrint('✅ [LogoutController] Backend auth data cleared');

      // 2. Invalidate ALL providers to ensure no stale data persists
      // Auth & User State
      ref.invalidate(currentUserProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(profileStatsProvider);
      ref.invalidate(balanceProvider);
      ref.invalidate(backendTokenProvider);
      
      // Core App State
      ref.invalidate(jobsProvider);
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(myProductsProvider);
      ref.invalidate(myProductsStatsProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(mySalesProvider);

      // Applications Handlers — invalidate role FIRST so apps refetch correctly
      ref.invalidate(app_providers.userRoleProvider);
      ref.invalidate(app_providers.myApplicationsProvider);
      ref.invalidate(app_providers.applicationStatsProvider);
      ref.invalidate(app_providers.applicationActionsProvider);

      // Navigation & Settings
      ref.invalidate(selectedIndexProvider);

      debugPrint('✅ [LogoutController] All state invalidated');
      
    } catch (e) {
      debugPrint('❌ [LogoutController] Logout error: $e');
      rethrow;
    }
  }

  /// Sign out Firebase AFTER navigation to login page.
  /// Called separately so the router rebuild doesn't fight the navigation.
  Future<void> signOutFirebase() async {
    try {
      await ref.read(authServiceProvider).signOut();
      debugPrint('✅ [LogoutController] Firebase signed out');
    } catch (e) {
      debugPrint('⚠️ [LogoutController] Firebase sign-out error: $e');
      // Non-critical — backend data is already cleared
    }
  }
}

// =====================================================
// AUTHENTICATION STATUS PROVIDER
// =====================================================

final isAuthenticatedProvider = Provider.autoDispose<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  // Also check backend token storage via authService
  final backendTokenAsync = ref.watch(backendTokenProvider);

  final firebaseLoggedIn = authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );

  final backendLoggedIn = backendTokenAsync.maybeWhen(
    data: (token) => token != null,
    orElse: () => false,
  );

  return firebaseLoggedIn && backendLoggedIn;
});

/// Provider to check if backend token exists in storage
/// Public so login handlers can invalidate it after sign-in
final backendTokenProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.getBackendToken();
});

// =====================================================
// USER ROLE PROVIDER (OPTIONAL - FOR ROLE-BASED ACCESS)
// =====================================================

final userRoleProvider = Provider.autoDispose<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.maybeWhen(
    data: (user) => user?.role,
    orElse: () => null,
  );
});

final isEmployerProvider = Provider.autoDispose<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'employer';
});

final isJobSeekerProvider = Provider.autoDispose<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == 'jobseeker' || role == 'job_seeker';
});
