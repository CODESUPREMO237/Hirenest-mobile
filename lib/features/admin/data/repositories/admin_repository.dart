// ==================== 2. ADMIN SERVICE ====================
// lib/features/admin/data/repositories/admin_repository.dart

import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/auth_service.dart';

class AdminService {
  final Dio _dio;
  final AuthService _authService;

  AdminService(this._dio, this._authService);

  // Dashboard Overview
  Future<Map<String, dynamic>> getDashboardOverview() async {
    final token = await _authService.getBackendToken();
    final response = await _dio.get(
      ApiEndpoints.adminDashboard,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['data'];
  }

  // Get All Users
  Future<Map<String, dynamic>> getUsers({
    String? role,
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final token = await _authService.getBackendToken();
    final response = await _dio.get(
      ApiEndpoints.adminUsers,
      queryParameters: {
        if (role != null) 'role': role,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['data'];
  }

  // Toggle User Block
  Future<void> toggleUserBlock(String userId, {String? reason}) async {
    final token = await _authService.getBackendToken();
    await _dio.put(
      ApiEndpoints.toggleUserBlock(userId),
      data: {'reason': reason},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Delete User
  Future<void> deleteUser(String userId) async {
    final token = await _authService.getBackendToken();
    await _dio.delete(
      ApiEndpoints.deleteUser(userId),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Moderate Job
  Future<void> moderateJob(String jobId, String action, {String? reason}) async {
    final token = await _authService.getBackendToken();
    await _dio.put(
      ApiEndpoints.moderateJob(jobId),
      data: {'action': action, 'reason': reason},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Moderate Product
  Future<void> moderateProduct(String productId, String action, {String? reason}) async {
    final token = await _authService.getBackendToken();
    await _dio.put(
      ApiEndpoints.moderateProduct(productId),
      data: {'action': action, 'reason': reason},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Get Reported Content
  Future<Map<String, dynamic>> getReportedContent() async {
    final token = await _authService.getBackendToken();
    final response = await _dio.get(
      ApiEndpoints.adminReported,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['data'];
  }
}