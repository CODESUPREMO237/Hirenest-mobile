// ============================================================================
// JOBS REPOSITORY (FIXED) - Data Layer
// lib/features/jobs/data/repositories/jobs_repository.dart
// ============================================================================

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/logger.dart';
import '../models/job_model.dart';
import '../../../applications/data/models/application_model.dart';
import '../../../../core/models/paginated_response.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(ref.read(dioProvider));
});

class JobsRepository {
  final Dio dio;

  JobsRepository(this.dio);

  // Get all jobs with filters
  Future<PaginatedResponse<JobModel>> getJobs({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? jobType,
    String? experienceLevel,
    String? location,
    double? minSalary,
    bool? remote,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
      if (category != null) 'category': category,
      if (jobType != null) 'jobType': jobType,
      if (experienceLevel != null) 'experienceLevel': experienceLevel,
      if (location != null) 'location': location,
      if (minSalary != null) 'minSalary': minSalary,
      if (remote != null) 'remote': remote,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };

    final response = await dio.get(
      ApiEndpoints.jobs,
      queryParameters: queryParams,
    );

    return PaginatedResponse.fromJson(
      response.data['data'],
          (json) => JobModel.fromJson(json),
    );
  }

  // Get job by ID
  Future<JobModel> getJob(String id) async {
    final response = await dio.get(ApiEndpoints.job(id));
    return JobModel.fromJson(response.data['data']['job']);
  }

  // Create job (Employers only)
  Future<JobModel> createJob({
    required String title,
    required String description,
    required String jobType,
    required String category,
    required String experienceLevel,
    required Map<String, dynamic> location,
    required Map<String, dynamic> salary,
    required List<Map<String, dynamic>> skills,
    required List<String> benefits,
    String? applicationDeadline,
  }) async {
    final response = await dio.post(
      ApiEndpoints.jobs,
      data: {
        'title': title,
        'description': description,
        'jobType': jobType,
        'category': category,
        'experienceLevel': experienceLevel,
        'location': location,
        'salary': salary,
        'requirements': {'skills': skills},
        'benefits': benefits,
        if (applicationDeadline != null)
          'applicationDeadline': applicationDeadline,
      },
    );

    return JobModel.fromJson(response.data['data']['job']);
  }

  // Update job
  Future<JobModel> updateJob(String id, Map<String, dynamic> updates) async {
    final response = await dio.put(
      ApiEndpoints.job(id),
      data: updates,
    );

    return JobModel.fromJson(response.data['data']['job']);
  }

  // Delete job
  Future<void> deleteJob(String id) async {
    await dio.delete(ApiEndpoints.job(id));
  }

  // Get my posted jobs (Employers)
  Future<PaginatedResponse<JobModel>> getMyJobs({
    int page = 1,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      if (status != null) 'status': status,
    };

    final response = await dio.get(
      ApiEndpoints.myJobs,
      queryParameters: queryParams,
    );

    return PaginatedResponse.fromJson(
      response.data['data'],
          (json) => JobModel.fromJson(json),
    );
  }

  // Fixed applyToJob method in jobs_repository.dart

  Future<ApplicationModel> applyToJob({
    required String jobId,
    required String coverLetter,
    required XFile resumeFile,
    required List<Map<String, dynamic>> screeningAnswers, // Made required to match signature
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // ✅ FIX: Convert screening answers to ensure all values are strings
      final sanitizedAnswers = screeningAnswers.map((ans) => {
        'question': ans['question'].toString(),
        'answer': ans['answer'].toString(), // Force any type to String
      }).toList();

      // ✅ FIX: Debug log to see what we're sending
      AppLogger.debug('Sending Application Data:');
      AppLogger.debug('  Cover Letter: $coverLetter');
      AppLogger.debug('  Resume: ${resumeFile.name}');
      AppLogger.debug('  Screening Answers: ${jsonEncode(sanitizedAnswers)}');

      final formData = FormData.fromMap({
        // ✅ CRITICAL: Ensure coverLetter is sent correctly
        'coverLetter': coverLetter,

        // ✅ Resume file
        'resume': await MultipartFile.fromFile(
          resumeFile.path,
          filename: resumeFile.name,
        ),

        // ✅ CRITICAL: Send screening answers as JSON string
        // The backend will parse this string back to JSON
        if (sanitizedAnswers.isNotEmpty)
          'screeningAnswers': jsonEncode(sanitizedAnswers),

        // ✅ Additional info if provided
        if (additionalInfo != null)
          'additionalInfo': jsonEncode(additionalInfo),
      });

      // ✅ Debug: Log the FormData fields (excluding file content)
      AppLogger.debug('FormData fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');

      final response = await dio.post(
        ApiEndpoints.applyJob(jobId),
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // DEBUG: Check what the server actually sent
      AppLogger.debug('Apply Response: ${response.data}');

      final responseData = response.data;

      // Check if 'data' and 'application' exist before parsing
      if (responseData['data'] != null && responseData['data']['application'] != null) {
        return ApplicationModel.fromJson(responseData['data']['application']);
      } else if (responseData['data'] != null) {
        // Fallback if the controller just returned { data: application }
        return ApplicationModel.fromJson(responseData['data']);
      } else {
        throw Exception('Unexpected response format: ${response.data}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Repository Apply Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<PaginatedResponse<ApplicationModel>> getMyApplications({
    int page = 1,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      if (status != null) 'status': status,
    };

    final response = await dio.get(
      ApiEndpoints.myApplications,
      queryParameters: queryParams,
    );

    // 🔥 DEBUG PRINT: Copy this into your console to see the real structure
    print('--- BACKEND RESPONSE DATA ---');
    print(jsonEncode(response.data['data']));
    print('-----------------------------');

    return PaginatedResponse.fromJson(
      response.data['data'],
          (json) => ApplicationModel.fromJson(json),
    );
  }

  // Get job applicants (Employers)
  Future<PaginatedResponse<ApplicationModel>> getJobApplicants(
      String jobId, {
        int page = 1,
        String? status,
      }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      if (status != null) 'status': status,
    };

    final response = await dio.get(
      ApiEndpoints.jobApplicants(jobId),
      queryParameters: queryParams,
    );

    return PaginatedResponse.fromJson(
      response.data['data'],
          (json) => ApplicationModel.fromJson(json),
    );
  }

  // Update application status (Employers)
  Future<ApplicationModel> updateApplicationStatus(
      String applicationId,
      String status, {
        String? notes,
        dynamic rating, // 👈 Change from int? to dynamic for safety
      }) async {
    final response = await dio.put(
      '${ApiEndpoints.application(applicationId)}/status',
      data: {
        'status': status,
        if (notes != null) 'notes': notes,
        // 👈 Ensure rating is sent as a pure number
        if (rating != null) 'rating': int.tryParse(rating.toString()) ?? rating,
      },
    );

    return ApplicationModel.fromJson(response.data['data']['application']);
  }

  // Withdraw application (Job Seekers)
  Future<ApplicationModel> withdrawApplication(String applicationId) async {
    final response = await dio.put(
      '${ApiEndpoints.application(applicationId)}/withdraw',
    );

    return ApplicationModel.fromJson(response.data['data']['application']);
  }

  // Get application statistics
  Future<Map<String, int>> getApplicationStats() async {
    final response = await dio.get(ApiEndpoints.applicationStats);
    final rawStats = response.data['data']['stats'] as Map;

    // Safely convert all values to int
    return rawStats.map((key, value) => MapEntry(
        key.toString(),
        int.tryParse(value.toString()) ?? 0
    ));
  }

  // Upload CV
  Future<Map<String, String>> uploadCV(XFile file) async {
    final formData = FormData.fromMap({
      'cv': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      ),
    });

    final response = await dio.post(
      '/users/me/cv',
      data: formData,
    );

    return {
      'url': response.data['data']['cv']['url'],
      'filename': response.data['data']['cv']['filename'],
    };
  }

  // Get featured jobs
  Future<List<JobModel>> getFeaturedJobs({int limit = 10}) async {
    final response = await dio.get(
      ApiEndpoints.featuredJobs,
      queryParameters: {'limit': limit},
    );

    final jobs = response.data['data']['jobs'] as List;
    return jobs.map((json) => JobModel.fromJson(json)).toList();
  }

  // Get similar jobs
  Future<List<JobModel>> getSimilarJobs(String jobId, {int limit = 5}) async {
    final response = await dio.get(
      '${ApiEndpoints.job(jobId)}/similar',
      queryParameters: {'limit': limit},
    );

    final jobs = response.data['data']['jobs'] as List;
    return jobs.map((json) => JobModel.fromJson(json)).toList();
  }

  // Get job categories
  Future<List<String>> getCategories() async {
    final response = await dio.get(ApiEndpoints.jobCategories);

    final categories = response.data['data']['categories'] as List;
    return categories.map((cat) => cat.toString()).toList();
  }

}