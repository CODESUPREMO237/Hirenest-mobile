// Company Repository
// lib/features/company/data/repositories/company_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/company_model.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(ref.read(dioProvider));
});

class CompanyRepository {
  final Dio dio;

  CompanyRepository(this.dio);

  // Get my company
  Future<CompanyModel> getMyCompany() async {
    try {
      final response = await dio.get(ApiEndpoints.myCompany);

      if (response.data['status'] == 'success') {
        return CompanyModel.fromJson(response.data['data']['company']);
      }

      throw Exception(response.data['message'] ?? 'Failed to load company');
    } catch (e) {
      rethrow;
    }
  }

  // Get company by ID
  Future<CompanyModel> getCompany(String id) async {
    try {
      final response = await dio.get(ApiEndpoints.company(id));

      if (response.data['status'] == 'success') {
        return CompanyModel.fromJson(response.data['data']['company']);
      }

      throw Exception(response.data['message'] ?? 'Failed to load company');
    } catch (e) {
      rethrow;
    }
  }
  // Add this inside the CompanyRepository class
// Update searchUsers to use the constant
  Future<List<UserModel>> searchUsers(String email) async {
    try {
      final response = await dio.get(
        ApiEndpoints.searchUsers,
        queryParameters: {'email': email},
      );

      if (response.data['status'] == 'success') {
        // ✅ FIX: Access response.data['data'] directly as the List
        final List<dynamic> usersList = response.data['data'];

        return usersList
            .map((json) => UserModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('Search Users Repository Error', error: e);
      rethrow;
    }
  }

  // Update addAdmin to use the functional constant
  Future<void> addAdmin(String companyId, String userId) async {
    try {
      await dio.post(
        ApiEndpoints.companyAdmins(companyId), // Use the helper method from ApiEndpoints
        data: {'userId': userId},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update removeAdmin to use the functional constant
  Future<void> removeAdmin(String companyId, String adminId) async {
    try {
      await dio.delete(
        ApiEndpoints.removeCompanyAdmin(companyId, adminId), // Use the helper method
      );
    } catch (e) {
      rethrow;
    }
  }
  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await dio.get(ApiEndpoints.userById(userId));

      if (response.data['status'] == 'success') {
        // Adjust the path based on your API's response structure
        // e.g., response.data['data']['user']
        return UserModel.fromJson(response.data['data']['user']);
      }

      throw Exception(response.data['message'] ?? 'Failed to fetch user details');
    } catch (e) {
      rethrow;
    }
  }

  // Get all companies
  Future<List<CompanyModel>> getAllCompanies({
    int page = 1,
    int limit = 20,
    String? search,
    String? industry,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (industry != null && industry.isNotEmpty) 'industry': industry,
      };

      final response = await dio.get(
        ApiEndpoints.companies,
        queryParameters: queryParams,
      );

      if (response.data['status'] == 'success') {
        final companies = (response.data['data']['companies'] as List)
            .map((json) => CompanyModel.fromJson(json))
            .toList();
        return companies;
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Create company
  Future<CompanyModel> createCompany(FormData formData) async {
    try {
      final response = await dio.post(
        ApiEndpoints.companies,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.data['status'] == 'success') {
        return CompanyModel.fromJson(response.data['data']['company']);
      }

      throw Exception(response.data['message'] ?? 'Failed to create company');
    } catch (e) {
      rethrow;
    }
  }

  // Update company
  Future<CompanyModel> updateCompany(String id, FormData formData) async {
    try {
      final response = await dio.put(
        ApiEndpoints.company(id),
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.data['status'] == 'success') {
        return CompanyModel.fromJson(response.data['data']['company']);
      }

      throw Exception(response.data['message'] ?? 'Failed to update company');
    } catch (e) {
      rethrow;
    }
  }

  // Delete company
  Future<void> deleteCompany(String id) async {
    try {
      await dio.delete(ApiEndpoints.company(id));
    } catch (e) {
      rethrow;
    }
  }
}