// =====================================================
// AUTH PROVIDER WITH LOGOUT MANAGEMENT
// lib/features/auth/presentation/providers/auth_provider.dart
// =====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/auth_service.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../home/presentation/pages/main_page.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

// =====================================================
// CORE AUTH PROVIDERS
// =====================================================

final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return await ref.read(authRepositoryProvider).getCurrentUser();
    },
    loading: () => null,
    error: (_, __) => null,
  );
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
      // 1. Sign out from auth service (Firebase + backend)
      await ref.read(authServiceProvider).signOut();

      // 2. Invalidate all user-related providers
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(balanceProvider);

      // 3. Reset navigation state
      ref.read(selectedIndexProvider.notifier).state = 0;

      // Add any other providers that need to be cleared:
      // ref.invalidate(jobsProvider);
      // ref.invalidate(chatsProvider);
      // ref.invalidate(marketplaceProvider);
      // ref.invalidate(applicationsProvider);
      // ref.invalidate(notificationsProvider);

    } catch (e) {
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

final isGuestProvider = Provider.autoDispose<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == null || role == 'guest' || role.isEmpty;
});