// =====================================================
// AUTH PROVIDER WITH CACHE-FIRST STRATEGY
// lib/features/auth/presentation/providers/auth_provider.dart
// =====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/auth_service.dart';
import '../../../chat/presentation/providers/chats_provider.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../home/presentation/pages/main_page.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

// Import marketplace providers
import '../../../marketplace/presentation/providers/PaginatedProductsNotifier.dart';
import '../../../marketplace/presentation/providers/my_products_provider.dart';

// Import applications provider (with alias to avoid conflict)
import '../../../applications/presentation/providers/applications_provider.dart'
as app_providers;

// Import notification service (not a provider that needs invalidating)
import '../../../../core/services/notification_service.dart';

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
        print('ℹ️ [currentUserProvider] No Firebase user');
        return null;
      }

      try {
        final authService = ref.read(authServiceProvider);

        // ✅ CACHE-FIRST: Try to get cached user data first
        print('📦 [currentUserProvider] Checking cache...');
        final cachedData = await authService.getCachedUserData();

        if (cachedData != null) {
          print('✅ [currentUserProvider] Using cached data for: ${cachedData['email']}');
          return UserModel.fromJson(cachedData);
        }

        // ✅ FALLBACK: Only fetch from server if no cache
        print('📡 [currentUserProvider] No cache, fetching from server...');
        final user = await ref.read(authRepositoryProvider).getCurrentUser();
        print('✅ [currentUserProvider] Server fetch successful: ${user.email}');
        return user;

      } catch (e, stackTrace) {
        print('❌ [currentUserProvider] Error: $e');

        // ✅ ULTIMATE FALLBACK: Try cache one more time
        try {
          final authService = ref.read(authServiceProvider);
          final cachedData = await authService.getCachedUserData();

          if (cachedData != null) {
            print('⚠️ [currentUserProvider] Using cached data as fallback after error');
            return UserModel.fromJson(cachedData);
          }
        } catch (cacheError) {
          print('❌ [currentUserProvider] Cache fallback also failed: $cacheError');
        }

        // If everything fails, rethrow
        rethrow;
      }
    },
    loading: () {
      print('⏳ [currentUserProvider] Auth state loading...');
      return null;
    },
    error: (error, stack) {
      print('❌ [currentUserProvider] Auth state error: $error');
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
    print('🔄 [refreshUserProvider] Manually refreshing user data...');
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

  /// Performs complete logout: signs out and invalidates all user-related state
  Future<void> logout() async {
    try {
      print('🚪 [LogoutController] Starting logout...');

      // 1. Sign out from auth service (Firebase + backend)
      await ref.read(authServiceProvider).signOut();
      print('✅ [LogoutController] Auth service signed out');

      // 2. Invalidate all user-related providers
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(balanceProvider);

      // 3. Invalidate jobs-related providers
      ref.invalidate(jobsProvider);

      // 4. Invalidate chat-related providers
      ref.invalidate(chatsProvider);

      // 5. Invalidate marketplace providers
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(myProductsProvider);

      // 6. Invalidate applications providers (using alias)
      ref.invalidate(app_providers.myApplicationsProvider);
      ref.invalidate(app_providers.applicationStatsProvider);
      ref.invalidate(app_providers.applicationActionsProvider);

      // 7. Reset navigation state
      ref.read(selectedIndexProvider.notifier).state = 0;

      print('✅ [LogoutController] All state cleared, logout complete');
    } catch (e) {
      print('❌ [LogoutController] Logout error: $e');
      rethrow;
    }
  }
}

// =====================================================
// AUTHENTICATION STATUS PROVIDER
// =====================================================

final isAuthenticatedProvider = Provider.autoDispose<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
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