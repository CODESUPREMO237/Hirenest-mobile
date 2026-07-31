import 'package:flutter/foundation.dart';
// ============================================================================
// JOBS PROVIDERS - State Management (COMPLETE - NO DUPLICATES)
// lib/features/jobs/presentation/providers/jobs_provider.dart
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/providers/global_error_provider.dart';
import '../../data/models/job_model.dart';
import '../../data/repositories/jobs_repository.dart';
import '../../../applications/data/models/application_model.dart';

// ============================================================================
// JOBS LIST PROVIDER
// ============================================================================
final jobsProvider = StateNotifierProvider<JobsNotifier, AsyncValue<List<JobModel>>>((ref) {
  return JobsNotifier(ref);
});

class JobsNotifier extends StateNotifier<AsyncValue<List<JobModel>>> {
  final Ref ref;
  int _currentPage = 1;
  bool _hasMore = true;
  JobFilters _filters = JobFilters();

  JobsNotifier(this.ref) : super(const AsyncValue.loading()) ;


  Future<void> loadJobs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
      ref.read(jobsPaginationLoadingProvider.notifier).state = false;
    }

    if (!_hasMore && !refresh) return;

    // Set pagination loading only when not refreshing
    if (!refresh) {
      ref.read(jobsPaginationLoadingProvider.notifier).state = true;
    }

    try {
      final repository = ref.read(jobsRepositoryProvider);
      final response = await repository.getJobs(
        page: _currentPage,
        search: _filters.search,
        category: _filters.category,
        jobType: _filters.jobType,
        experienceLevel: _filters.experienceLevel,
        location: _filters.location,
        minSalary: _filters.minSalary,
        remote: _filters.remote,
        sortBy: _filters.sortBy,
        sortOrder: _filters.sortOrder,
      );

      final newJobs = response.items;
      _hasMore = response.hasMore;

      state = AsyncValue.data(
        refresh ? newJobs : [...?state.value, ...newJobs],
      );

      _currentPage++;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      ref.read(jobsPaginationLoadingProvider.notifier).state = false;
    }
  }

  void updateFilters(JobFilters filters) {
    _filters = filters;
    loadJobs(refresh: true);
  }

  void search(String query) {
    _filters = _filters.copyWith(search: query);
    loadJobs(refresh: true);
  }
}
// Add this after JobsNotifier class
final jobsPaginationLoadingProvider = StateProvider<bool>((ref) => false);

// ============================================================================
// JOB DETAIL PROVIDER - WITH AUTODISPOSE FOR VIEW TRACKING
// ⚠️ IMPORTANT: Only ONE declaration of this provider should exist!
// ============================================================================
final jobDetailProvider = FutureProvider.autoDispose.family<JobModel, String>(
      (ref, id) async {
    debugPrint('🔍 [jobDetailProvider] Fetching job ID: $id');
    final repository = ref.read(jobsRepositoryProvider);
    final job = await repository.getJob(id);
    debugPrint('✅ [jobDetailProvider] Loaded: ${job.title}');
    debugPrint('   📊 Views: ${job.stats?.views ?? 0}');
    debugPrint('   👤 Unique: ${job.stats?.uniqueViews ?? 0}');
    debugPrint('   📝 Apps: ${job.stats?.applications ?? 0}');
    return job;
  },
);

// ============================================================================
// MY JOBS PROVIDER (EMPLOYERS)
// ============================================================================
final myJobsProvider = StateNotifierProvider<MyJobsNotifier, AsyncValue<List<JobModel>>>((ref) {
  return MyJobsNotifier(ref);
});

class MyJobsNotifier extends StateNotifier<AsyncValue<List<JobModel>>> {
  final Ref ref;

  MyJobsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadJobs();
  }

  Future<void> loadJobs() async {
    try {
      final repository = ref.read(jobsRepositoryProvider);
      final response = await repository.getMyJobs();
      state = AsyncValue.data(response.items);
    } catch (e, stack) {
      if (e is DioException) {
        final isConnectionError = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown;

        if (isConnectionError) {
          debugPrint('🚨 [myJobsProvider] Critical connection failure — triggering global overlay');
          ref.read(globalCriticalErrorProvider.notifier).state = CriticalError(
            message: 'Unable to connect to the server. Please check your internet connection.',
            onRetry: () => ref.read(myJobsProvider.notifier).loadJobs(),
          );
        }
      }
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      final repository = ref.read(jobsRepositoryProvider);
      await repository.deleteJob(jobId);
      state = state.whenData(
            (jobs) => jobs.where((j) => j.id != jobId).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // ✅ This method updates a job locally without refetching
  void updateLocalJob(JobModel updatedJob) {
    state = state.whenData((jobs) {
      return jobs.map((j) => j.id == updatedJob.id ? updatedJob : j).toList();
    });
  }
}

// ============================================================================
// MY APPLICATIONS PROVIDER (JOB SEEKERS)
// ============================================================================
final myApplicationsProvider = StateNotifierProvider<MyApplicationsNotifier, AsyncValue<List<ApplicationModel>>>((ref) {
  return MyApplicationsNotifier(ref);
});

class MyApplicationsNotifier extends StateNotifier<AsyncValue<List<ApplicationModel>>> {
  final Ref ref;

  MyApplicationsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadApplications();
  }

  Future<void> loadApplications() async {
    try {
      final repository = ref.read(jobsRepositoryProvider);
      final response = await repository.getMyApplications();
      state = AsyncValue.data(response.items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> withdrawApplication(String applicationId) async {
    try {
      final repository = ref.read(jobsRepositoryProvider);
      await repository.withdrawApplication(applicationId);
      state = state.whenData(
            (apps) => apps.where((a) => a.id != applicationId).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }
}

// ============================================================================
// OTHER PROVIDERS
// ============================================================================

// Application stats provider
final applicationStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.read(jobsRepositoryProvider);
  return await repository.getApplicationStats();
});

// Featured jobs provider
final featuredJobsProvider = FutureProvider<List<JobModel>>((ref) async {
  try {
    final repository = ref.read(jobsRepositoryProvider);
    return await repository.getFeaturedJobs();
  } catch (e) {
    if (e is DioException) {
      final isConnectionError = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;

      if (isConnectionError) {
        debugPrint('🚨 [featuredJobsProvider] Critical connection failure — triggering global overlay');
        ref.read(globalCriticalErrorProvider.notifier).state = CriticalError(
          message: 'Unable to connect to the server. Please check your internet connection.',
          onRetry: () => ref.invalidateSelf(),
        );
      }
    }
    rethrow;
  }
});

// ============================================================================
// JOB UPDATE CONTROLLER (NEW)
// Manages the state of editing or creating a job
// ============================================================================
final jobUpdateControllerProvider = StateNotifierProvider<JobUpdateController, AsyncValue<void>>((ref) {
  return JobUpdateController(ref);
});

class JobUpdateController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  JobUpdateController(this.ref) : super(const AsyncData(null));

  Future<bool> updateJob(String jobId, Map<String, dynamic> updates) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(jobsRepositoryProvider);
      final updatedJob = await repository.updateJob(jobId, updates);

      // ✅ Update the local state in myJobsProvider so the UI reflects changes instantly
      ref.read(myJobsProvider.notifier).updateLocalJob(updatedJob);

      // ✅ Invalidate details in case the user goes to the detail page
      ref.invalidate(jobDetailProvider(jobId));

      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

// ============================================================================
// JOB FILTERS MODEL
// ============================================================================
class JobFilters {
  final String? search;
  final String? category;
  final String? jobType;
  final String? experienceLevel;
  final String? location;
  final double? minSalary;
  final bool? remote;
  final String? sortBy;
  final String? sortOrder;

  JobFilters({
    this.search,
    this.category,
    this.jobType,
    this.experienceLevel,
    this.location,
    this.minSalary,
    this.remote,
    this.sortBy,
    this.sortOrder,
  });

  JobFilters copyWith({
    String? search,
    String? category,
    String? jobType,
    String? experienceLevel,
    String? location,
    double? minSalary,
    bool? remote,
    String? sortBy,
    String? sortOrder,
  }) {
    return JobFilters(
      search: search ?? this.search,
      category: category ?? this.category,
      jobType: jobType ?? this.jobType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      location: location ?? this.location,
      minSalary: minSalary ?? this.minSalary,
      remote: remote ?? this.remote,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  bool get hasFilters =>
      category != null ||
          jobType != null ||
          experienceLevel != null ||
          location != null ||
          minSalary != null ||
          remote != null;
}
