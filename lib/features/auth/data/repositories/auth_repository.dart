// Auth Repository
// ============================================================================
// auth_repository.dart
// lib/features/auth/data/repositories/auth_repository.dart
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  final Dio dio;

  AuthRepository(this.dio);

  Future<UserModel> getCurrentUser() async {
    final response = await dio.get('/users/me');
    return UserModel.fromJson(response.data['data']['user']);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> profileData) async {
    final response = await dio.put(
      '/users/me',
      data: {'profile': profileData},
    );
    return UserModel.fromJson(response.data['data']['user']);
  }

  Future<String> uploadAvatar(FormData formData) async {
    final response = await dio.put('/users/me/avatar', data: formData);
    return response.data['data']['avatar']['url'];
  }

  Future<Map<String, String>> uploadCV(FormData formData) async {
    final response = await dio.post('/users/me/cv', data: formData);
    return {
      'url': response.data['data']['cv']['url'],
      'filename': response.data['data']['cv']['filename'],
    };
  }

  Future<void> updateEmail(String newEmail) async {
    await dio.put('/users/me/email', data: {'newEmail': newEmail});
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    await dio.put('/users/me/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> deleteAccount() async {
    await dio.delete('/users/me');
  }
}