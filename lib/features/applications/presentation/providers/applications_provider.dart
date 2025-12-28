// ============================================================================
// applications_provider.dart - COMPLETE CONSOLIDATED FILE
// lib/features/applications/presentation/providers/applications_provider.dart
// ============================================================================
// 
// ⚠️ IMPORTANT: This is the ONLY applications provider file you should have.
// Delete any other files with similar names like:
// - application_actions_notifier.dart
// - application_provider.dart (without 's')
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/applications_repository.dart';

// =====================================================
// REPOSITORY PROVIDER
// =====================================================
final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  final dio = ref.read(dioProvider);
  return ApplicationsRepository(dio);
});

// =====================================================
// USER ROLE PROVIDER
// =====================================================
/// Get current user's role (NOT auto-disposed - we want this to persist)
final userRoleProvider = FutureProvider<String>((ref) async {
  final authService = ref.read(authServiceProvider);
  final user = authService.currentFirebaseUser;

  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Get role from secure storage
  final storage = const FlutterSecureStorage();
  final role = await storage.read(key: StorageKeys.userRole);

  return role ?? 'jobseeker'; // Default to jobseeker
});

// =====================================================
// APPLICATIONS PROVIDER (ROLE-AWARE)
// =====================================================
/// ✅ Role-aware applications provider
/// - Job Seekers: Get their own applications
/// - Employers: Get applications for ALL their jobs
final myApplicationsProvider = FutureProvider.autoDispose<List<ApplicationModel>>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  final repository = ref.read(applicationsRepositoryProvider);

  if (role == 'jobseeker') {
    print('📋 [Applications] Fetching job seeker applications...');
    final response = await repository.getMyApplications();
    final applicationsList = response['applications'] as List;
    return applicationsList
        .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  } else if (role == 'employer') {
    print('📋 [Applications] Fetching employer applications...');
    final rawList = await repository.getEmployerApplications();
    return rawList
        .map((json) => ApplicationModel.fromJson(json))
        .toList();
  } else {
    throw Exception('Unknown role: $role');
  }
});

// =====================================================
// APPLICATION STATISTICS (ROLE-AWARE)
// =====================================================
/// Application statistics with safe type conversion
final applicationStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  final repository = ref.read(applicationsRepositoryProvider);

  if (role == 'jobseeker') {
    final applications = await ref.watch(myApplicationsProvider.future);

    int countByStatus(String targetStatus) {
      return applications.where((a) {
        final status = a.status.toString().toLowerCase();
        return status == targetStatus.toLowerCase();
      }).length;
    }

    return {
      'total': applications.length,
      'pending': countByStatus('pending'),
      'shortlisted': countByStatus('shortlisted'),
      'rejected': countByStatus('rejected'),
    };
  } else if (role == 'employer') {
    final stats = await repository.getEmployerApplicationStats();

    // Safe conversion to int
    return stats.map((key, value) {
      int intValue;
      if (value is int) {
        intValue = value;
      } else if (value is double) {
        intValue = value.toInt();
      } else if (value is String) {
        intValue = int.tryParse(value) ?? 0;
      } else {
        intValue = 0;
      }
      return MapEntry(key, intValue);
    });
  } else {
    throw Exception('Unknown role: $role');
  }
});

// =====================================================
// APPLICATION ACTIONS NOTIFIER
// =====================================================
class ApplicationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final ApplicationsRepository _repository;

  ApplicationActionsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> applyToJob({
    required String jobId,
    String? coverLetter,
    required XFile resume,
    List<Map<String, String>>? screeningAnswers,
    Map<String, dynamic>? additionalInfo,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.applyToJob(
        jobId: jobId,
        coverLetter: coverLetter,
        resume: resume,
        screeningAnswers: screeningAnswers,
        additionalInfo: additionalInfo,
      );
    });
  }

  Future<void> withdrawApplication(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.withdrawApplication(id);
    });
  }

  Future<void> shortlistApplication(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.shortlistApplication(id);
    });
  }

  Future<void> rejectApplication({
    required String id,
    String? reason,
    String? feedback,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.rejectApplication(
        id: id,
        reason: reason,
        feedback: feedback,
      );
    });
  }

  Future<void> acceptApplication(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateApplicationStatus(
        id: id,
        status: 'accepted',
      );
    });
  }

  Future<void> scheduleInterview({
    required String id,
    required DateTime scheduledAt,
    String? location,
    String? meetingLink,
    String? notes,
    String? type,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.scheduleInterview(
        id: id,
        scheduledAt: scheduledAt,
        location: location,
        meetingLink: meetingLink,
        notes: notes,
        type: type,
      );
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Provider for the actions notifier
final applicationActionsProvider = StateNotifierProvider<ApplicationActionsNotifier, AsyncValue<void>>((ref) {
  return ApplicationActionsNotifier(ref.read(applicationsRepositoryProvider));
});