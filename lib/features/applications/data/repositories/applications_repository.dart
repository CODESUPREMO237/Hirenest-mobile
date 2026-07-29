import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/logger.dart';
import '../models/application_model.dart';
import 'package:image_picker/image_picker.dart';

class ApplicationsRepository {
  final Dio _dio;

  ApplicationsRepository(this._dio);

  // Get my applications (Job Seeker)
  Future<Map<String, dynamic>> getMyApplications({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('📋 [Repository] getMyApplications called');
      debugPrint('   Status filter: ${status ?? "none"}');
      debugPrint('   Page: $page, Limit: $limit');

      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) queryParams['status'] = status;

      debugPrint('   Endpoint: ${ApiEndpoints.myApplications}');
      debugPrint('   Full URL: ${ApiEndpoints.baseUrl}${ApiEndpoints.myApplications}');

      final response = await _dio.get(
        ApiEndpoints.myApplications,
        queryParameters: queryParams,
      );

      debugPrint('✅ [Repository] Response received');
      debugPrint('   Status code: ${response.statusCode}');

      return response.data['data'];
    } catch (e) {
      debugPrint('❌ [Repository] Error in getMyApplications: $e');
      throw _handleError(e);
    }
  }

  // Get job applicants (Employer)
  Future<List<ApplicationModel>> getJobApplicants({
    required String jobId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        ApiEndpoints.jobApplicants(jobId),
        queryParameters: queryParams,
      );

      final List applicationsJson = response.data['data']['applications'];
      return applicationsJson
          .map((json) => ApplicationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get application by ID
  Future<ApplicationModel> getApplicationById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.application(id));
      return ApplicationModel.fromJson(response.data['data']['application']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Apply to a job with resume upload
  Future<ApplicationModel> applyToJob({
    required String jobId,
    String? coverLetter,
    required XFile resume,
    List<Map<String, String>>? screeningAnswers,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('📤 APPLYING TO JOB - REPOSITORY LAYER');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('Job ID: $jobId');
      debugPrint('Cover Letter: ${coverLetter?.isEmpty ?? true ? "EMPTY/NULL" : "Present (${coverLetter!.length} chars)"}');
      debugPrint('Resume File: ${resume.name}');
      debugPrint('Screening Answers: ${screeningAnswers?.length ?? 0}');
      debugPrint('Additional Info: ${additionalInfo?.keys.length ?? 0} fields');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('');

      // Create multipart form data
      final formData = FormData();

      // Add cover letter if provided
      if (coverLetter != null && coverLetter.trim().isNotEmpty) {
        formData.fields.add(MapEntry('coverLetter', coverLetter.trim()));
        debugPrint('✅ Added cover letter to form data');
      } else {
        debugPrint('⚠️  Cover letter is empty or null - not sending');
      }

      // Add resume file
      final fileName = resume.name;
      final multipartFile = await MultipartFile.fromFile(
        resume.path,
        filename: fileName,
      );
      formData.files.add(MapEntry('resume', multipartFile));
      debugPrint('✅ Added resume file: $fileName');

      // Add screening answers (if any)
      if (screeningAnswers != null && screeningAnswers.isNotEmpty) {
        final jsonString = jsonEncode(screeningAnswers);
        formData.fields.add(MapEntry('screeningAnswers', jsonString));
        debugPrint('✅ Added ${screeningAnswers.length} screening answers');
      }

      // Add additional info (if any)
      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        final jsonString = jsonEncode(additionalInfo);
        formData.fields.add(MapEntry('additionalInfo', jsonString));
        debugPrint('✅ Added additional info');
      }

      debugPrint('');
      debugPrint('📡 Sending POST request to: /jobs/$jobId/apply');
      debugPrint('');

      // Make the API request
      final response = await _dio.post(
        '/jobs/$jobId/apply',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('✅ APPLICATION RESPONSE RECEIVED');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response keys: ${response.data.keys}');

      if (response.data['data'] != null) {
        debugPrint('Data keys: ${response.data['data'].keys}');
        if (response.data['data']['application'] != null) {
          final app = response.data['data']['application'];
          debugPrint('Application ID: ${app['_id']}');
          debugPrint('Has coverLetter: ${app['coverLetter'] != null}');
          debugPrint('Has resume: ${app['resume'] != null}');
          debugPrint('Has applicant: ${app['applicant'] != null}');

          if (app['applicant'] is Map) {
            debugPrint('Applicant type: MAP (POPULATED) ✅');
            debugPrint('Has profile: ${app['applicant']['profile'] != null}');
            debugPrint('Has jobSeekerProfile: ${app['applicant']['jobSeekerProfile'] != null}');
          } else {
            debugPrint('Applicant type: STRING (NOT POPULATED) ❌');
          }
        }
      }
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('');

      return ApplicationModel.fromJson(response.data['data']['application']);
    } on DioException catch (e) {
      debugPrint('');
      debugPrint('❌ DIO ERROR in applyToJob:');
      debugPrint('   Type: ${e.type}');
      debugPrint('   Message: ${e.message}');
      if (e.response != null) {
        debugPrint('   Status Code: ${e.response?.statusCode}');
        debugPrint('   Response Data: ${e.response?.data}');
      }
      debugPrint('');
      throw _handleError(e);
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌ GENERAL ERROR in applyToJob:');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('');
      rethrow;
    }
  }

  // Withdraw application
  Future<void> withdrawApplication(String id) async {
    try {
      await _dio.put(ApiEndpoints.withdrawApplication(id));
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Update application status (Employer)
  Future<ApplicationModel> updateApplicationStatus({
    required String id,
    required String status,
    String? notes,
    int? rating,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.updateApplicationStatus(id),
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
          if (rating != null) 'rating': rating,
        },
      );

      return ApplicationModel.fromJson(response.data['data']['application']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Shortlist application (Employer)
  Future<ApplicationModel> shortlistApplication(String id) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.shortlistApplication(id),
      );

      return ApplicationModel.fromJson(response.data['data']['application']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Reject application (Employer)
  Future<ApplicationModel> rejectApplication({
    required String id,
    String? reason,
    String? feedback,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.rejectApplication(id),
        data: {
          if (reason != null) 'reason': reason,
          if (feedback != null) 'feedback': feedback,
        },
      );

      return ApplicationModel.fromJson(response.data['data']['application']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Schedule interview (Employer)
  Future<ApplicationModel> scheduleInterview({
    required String id,
    required DateTime scheduledAt,
    String? location,
    String? meetingLink,
    String? notes,
    String? type,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.scheduleInterview(id),
        data: {
          'scheduledAt': scheduledAt.toIso8601String(),
          if (location != null) 'location': location,
          if (meetingLink != null) 'meetingLink': meetingLink,
          if (notes != null) 'notes': notes,
          if (type != null) 'type': type,
        },
      );

      return ApplicationModel.fromJson(response.data['data']['application']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get application statistics
  Future<Map<String, dynamic>> getApplicationStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.applicationStats);
      return response.data['data']['stats'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all applications for employer's jobs (OPTIMIZED - Single API call)
  Future<List<Map<String, dynamic>>> getEmployerApplications({
    int page = 1,
    String? status,
  }) async {
    try {
      debugPrint('📋 [Repository] Fetching employer applications (OPTIMIZED)...');
      debugPrint('   Endpoint: ${ApiEndpoints.employerApplications}');
      debugPrint('   Page: $page, Status: ${status ?? "all"}');

      final startTime = DateTime.now();

      // ✅ SINGLE API CALL using new optimized endpoint
      final response = await _dio.get(
        ApiEndpoints.employerApplications,
        queryParameters: {
          'page': page,
          'limit': 100,
          if (status != null) 'status': status,
        },
      );

      final applications = (response.data['data']['applications'] as List)
          .map((app) => app as Map<String, dynamic>)
          .toList();

      final duration = DateTime.now().difference(startTime);

      debugPrint('✅ [Repository] Fetched ${applications.length} applications in ${duration.inMilliseconds}ms');
      if (applications.isNotEmpty) {
        debugPrint('   ⚡ ${(duration.inMilliseconds / applications.length).toStringAsFixed(1)}ms per application');
      }

      return applications;
    } catch (e) {
      AppLogger.error('Error fetching employer applications', error: e);
      rethrow;
    }
  }

  /// Get application statistics for employer
  Future<Map<String, dynamic>> getEmployerApplicationStats() async {
    try {

      final response = await _dio.get(ApiEndpoints.employerApplicationStats);
      return response.data['data']['stats'] as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error fetching employer stats', error: e);
      rethrow;
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final message = error.response?.data['message'] ?? 'An error occurred';
        debugPrint('❌ [Repository] API Error: $message');
        debugPrint('   Status: ${error.response?.statusCode}');
        debugPrint('   Data: ${error.response?.data}');
        return message;
      }
      debugPrint('❌ [Repository] Network error');
      return 'Network error. Please check your connection.';
    }
    debugPrint('❌ [Repository] Unknown error: $error');
    return error.toString();
  }
}