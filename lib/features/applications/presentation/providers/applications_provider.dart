// ============================================================================
// applications_provider.dart - FIXED VERSION WITH PROPER ROLE HANDLING
// lib/features/applications/presentation/providers/applications_provider.dart
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
// USER ROLE PROVIDER - ALWAYS FRESH FROM STORAGE
// =====================================================
final userRoleProvider = FutureProvider<String>((ref) async {
  print('');
  print('═══════════════════════════════════════════════════');
  print('👤 [UserRoleProvider] FETCHING USER ROLE');
  print('═══════════════════════════════════════════════════');

  const storage = FlutterSecureStorage();

  // ✅ Get role from storage (this is the source of truth)
  final role = await storage.read(key: StorageKeys.userRole);

  print('   Stored Role: ${role ?? "NULL"}');

  if (role == null || role.isEmpty) {
    print('❌ [UserRoleProvider] No role found in storage!');
    print('   This usually means:');
    print('   1. User is not logged in');
    print('   2. Logout didn\'t clear properly');
    print('   3. Login didn\'t save role correctly');
    print('═══════════════════════════════════════════════════');
    throw Exception('User role not found. Please login again.');
  }

  print('✅ [UserRoleProvider] Role retrieved: $role');
  print('═══════════════════════════════════════════════════');
  print('');

  return role;
});

// =====================================================
// APPLICATIONS PROVIDER (ROLE-AWARE)
// =====================================================
final myApplicationsProvider = FutureProvider.autoDispose<List<ApplicationModel>>((ref) async {
  print('');
  print('═══════════════════════════════════════════════════');
  print('📋 [Applications] Fetching applications...');

  // ✅ Wait for role to be determined
  final role = await ref.watch(userRoleProvider.future);
  print('📋 [Applications] User role: $role');

  final repository = ref.read(applicationsRepositoryProvider);

  try {
    List<ApplicationModel> applications;

    if (role == 'employer') {
      print('📋 [Applications] Calling getEmployerApplications() for employer');
      print('   This will fetch applications across all posted jobs');

      final rawList = await repository.getEmployerApplications();
      applications = rawList
          .map((json) => ApplicationModel.fromJson(json))
          .toList();

    } else if (role == 'jobseeker') {
      print('📋 [Applications] Calling getMyApplications() for jobseeker');
      print('   Endpoint: /applications/my-applications');

      final response = await repository.getMyApplications();
      final applicationsList = response['applications'] as List;
      applications = applicationsList
          .map((json) => ApplicationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      print('❌ [Applications] Unknown role: $role');
      print('═══════════════════════════════════════════════════');
      print('');
      throw Exception('Unknown role: $role');
    }

    print('✅ [Applications] Successfully fetched ${applications.length} applications');
    print('═══════════════════════════════════════════════════');
    print('');

    return applications;
  } catch (e, stackTrace) {
    print('❌ [Applications] Error fetching applications: $e');
    print('   Stack trace: $stackTrace');
    print('═══════════════════════════════════════════════════');
    print('');
    rethrow;
  }
});

// =====================================================
// APPLICATION STATISTICS (ROLE-AWARE)
// =====================================================
final applicationStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  final repository = ref.read(applicationsRepositoryProvider);

  print('📊 [Stats] Fetching stats for role: $role');

  if (role == 'jobseeker') {
    // For job seekers, calculate stats from their applications
    final applications = await ref.watch(myApplicationsProvider.future);

    int countByStatus(String targetStatus) {
      return applications.where((a) {
        final status = a.status.toString().toLowerCase();
        return status == targetStatus.toLowerCase();
      }).length;
    }

    final stats = {
      'total': applications.length,
      'pending': countByStatus('pending'),
      'shortlisted': countByStatus('shortlisted'),
      'rejected': countByStatus('rejected'),
      'reviewing': countByStatus('reviewing'),
      'interviewing': countByStatus('interviewing'),
    };

    print('✅ [Stats] Job seeker stats: $stats');
    return stats;

  } else if (role == 'employer') {
    // For employers, get stats from API
    try {
      final stats = await repository.getEmployerApplicationStats();

      // Safe conversion to int
      final convertedStats = stats.map((key, value) {
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

      print('✅ [Stats] Employer stats: $convertedStats');
      return convertedStats;
    } catch (e) {
      print('❌ [Stats] Error fetching employer stats: $e');
      rethrow;
    }

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

final applicationActionsProvider = StateNotifierProvider<ApplicationActionsNotifier, AsyncValue<void>>((ref) {
  return ApplicationActionsNotifier(ref.read(applicationsRepositoryProvider));
});

// ============================================================================
// DEBUGGING HELPER
// ============================================================================

/// ✅ Debug provider to check auth state
final authDebugProvider = FutureProvider<Map<String, String?>>((ref) async {
  const storage = FlutterSecureStorage();

  return {
    'userId': await storage.read(key: StorageKeys.userId),
    'userEmail': await storage.read(key: StorageKeys.userEmail),
    'userRole': await storage.read(key: StorageKeys.userRole),
    'hasAuthToken': await storage.read(key: StorageKeys.authToken) != null ? 'YES' : 'NO',
  };
});