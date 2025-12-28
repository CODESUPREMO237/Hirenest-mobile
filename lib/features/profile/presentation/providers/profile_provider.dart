// Profile Provider - Complete with Marketplace Stats
// =====================================================
// PROFILE PROVIDERS
// lib/features/profile/presentation/providers/profile_provider.dart
// =====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/models/profile_model.dart';

/// Provider for the current user's profile
final profileProvider = FutureProvider<ProfileModel>((ref) async {
  return await ref.read(profileRepositoryProvider).getProfile();
});

/// Provider for profile statistics from marketplace
final profileStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final profile = await ref.watch(profileProvider.future);

  return {
    'productsPosted': profile.marketplaceStats?.productsPosted ?? 0,
    'activeProducts': profile.marketplaceStats?.activeProducts ?? 0,
    'totalViews': profile.marketplaceStats?.totalViews ?? 0,
    'rating': (profile.marketplaceStats?.sellerRating?.average ?? 0).round(),
  };
});

/// Provider to check if profile is complete
final isProfileCompleteProvider = Provider<bool>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.maybeWhen(
    data: (profile) {
      return profile.profile?.firstName != null &&
          profile.profile?.lastName != null &&
          profile.profile?.phone != null &&
          profile.profile?.location?.city != null;
    },
    orElse: () => false,
  );
});

/// Provider for user's full name
final userFullNameProvider = Provider<String>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.maybeWhen(
    data: (profile) {
      final firstName = profile.profile?.firstName ?? '';
      final lastName = profile.profile?.lastName ?? '';
      if (firstName.isEmpty && lastName.isEmpty) {
        return profile.email.split('@').first; // Fallback to email username
      }
      return '$firstName $lastName'.trim();
    },
    orElse: () => 'User',
  );
});

/// Provider for user's initials (useful for avatars)
final userInitialsProvider = Provider<String>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.maybeWhen(
    data: (profile) {
      final firstName = profile.profile?.firstName ?? '';
      final lastName = profile.profile?.lastName ?? '';

      if (firstName.isEmpty && lastName.isEmpty) {
        final email = profile.email;
        return email.isNotEmpty ? email[0].toUpperCase() : 'U';
      }

      final firstInitial = firstName.isNotEmpty ? firstName[0] : '';
      final lastInitial = lastName.isNotEmpty ? lastName[0] : '';
      return '$firstInitial$lastInitial'.toUpperCase();
    },
    orElse: () => 'U',
  );
});

/// Provider to check if user has uploaded CV
final hasCVProvider = Provider<bool>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.maybeWhen(
    data: (profile) {
      // Check if jobSeekerProfile exists and if it contains a resume
      return profile?.jobSeekerProfile?.resume != null;
    },
    orElse: () => false,
  );
});
/// Provider for seller rating
final sellerRatingProvider = Provider<Map<String, dynamic>>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.maybeWhen(
    data: (profile) {
      final rating = profile.marketplaceStats?.sellerRating;
      return {
        'average': rating?.average ?? 0.0,
        'count': rating?.count ?? 0,
        'hasRating': rating != null && rating.count > 0,
      };
    },
    orElse: () => {
      'average': 0.0,
      'count': 0,
      'hasRating': false,
    },
  );
});

/// Provider to check if user has any products
final hasProductsProvider = Provider<bool>((ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.maybeWhen(
    data: (profile) => (profile.marketplaceStats?.productsPosted ?? 0) > 0,
    orElse: () => false,
  );
});