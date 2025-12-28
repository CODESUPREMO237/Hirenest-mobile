// profile_repository.dart - Updated with jobseeker fields

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_preferences_model.dart';
import '../models/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(dioProvider));
});

class ProfileRepository {
  final Dio dio;

  ProfileRepository(this.dio);

  Future<ProfileModel> getProfile() async {
    final response = await dio.get('/users/me');
    return ProfileModel.fromJson(response.data['data']['user']);
  }

  Future<ProfileModel> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? city,
    String? country,
    // Jobseeker fields
    List<SkillModel>? skills,
    List<EducationModel>? education,
    List<ExperienceModel>? experience,
    PreferencesModel? preferences,
  }) async {
    final Map<String, dynamic> requestData = {};

    // Build the profile map
    final Map<String, dynamic> profileMap = {};
    if (firstName != null && firstName.isNotEmpty) profileMap['firstName'] = firstName;
    if (lastName != null && lastName.isNotEmpty) profileMap['lastName'] = lastName;
    if (phone != null && phone.isNotEmpty) profileMap['phone'] = phone;
    if (bio != null && bio.isNotEmpty) profileMap['bio'] = bio;

    // Build location map
    final Map<String, dynamic> locationMap = {};
    if (city != null && city.trim().isNotEmpty) locationMap['city'] = city.trim();
    if (country != null && country.trim().isNotEmpty) locationMap['country'] = country.trim();

    if (locationMap.isNotEmpty) {
      profileMap['location'] = locationMap;
    }

    if (profileMap.isNotEmpty) {
      requestData['profile'] = profileMap;
    }

    // Build jobseeker profile map
    if (skills != null || education != null || experience != null || preferences != null) {
      final Map<String, dynamic> jobSeekerMap = {};

      if (skills != null) {
        jobSeekerMap['skills'] = skills.map((s) => s.toJson()).toList();
      }
      if (education != null) {
        jobSeekerMap['education'] = education.map((e) => e.toJson()).toList();
      }
      if (experience != null) {
        jobSeekerMap['experience'] = experience.map((e) => e.toJson()).toList();
      }
      if (preferences != null) {
        jobSeekerMap['preferences'] = preferences.toJson();
      }

      if (jobSeekerMap.isNotEmpty) {
        requestData['jobSeekerProfile'] = jobSeekerMap;
      }
    }

    if (kDebugMode) {
      print("SENDING DATA: $requestData");
    }

    final response = await dio.put('/users/me', data: requestData);
    return ProfileModel.fromJson(response.data['data']['user']);
  }

  Future<void> deleteCV() async {
    await dio.delete('/users/me/cv');
  }

  Future<String> uploadAvatar(XFile file) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    final response = await dio.put('/users/me/avatar', data: formData);
    return response.data['data']['avatar'] as String;
  }

  Future<Map<String, dynamic>> uploadCV(XFile file) async {
    final formData = FormData.fromMap({
      'cv': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    final response = await dio.post('/users/me/cv', data: formData);
    return response.data['data']['resume'];
  }

  Future<void> deleteAccount() async {
    await dio.delete('/users/me');
  }

  Future<void> updateNotificationPreferences(
      NotificationPreferences preferences,
      ) async {
    try {
      await dio.put(
        '${ApiEndpoints.me}/notifications',
        data: preferences.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearNotification(DateTime timestamp) async {
    try {
      await dio.delete(
        '${ApiEndpoints.me}/users/me/notifications/${timestamp.millisecondsSinceEpoch}',
      );
    } catch (e) {
      throw 'Failed to clear notification: $e';
    }
  }

  Future<void> uploadFCMToken(String token) async {
    await dio.post('/users/me/fcm-token', data: {'token': token});
  }

  Future<void> updatePrivacySettings({
    String? profileVisibility,
    bool? showEmail,
    bool? showPhone,
    bool? biometricLogin,
  }) async {
    try {
      await dio.put(
        '${ApiEndpoints.me}/privacy',
        data: {
          'privacySettings': {
            if (profileVisibility != null) 'profileVisibility': profileVisibility,
            if (showEmail != null) 'showEmail': showEmail,
            if (showPhone != null) 'showPhone': showPhone,
            if (biometricLogin != null) 'biometricLogin': biometricLogin,
          },
        },
      );
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await dio.post('/auth/password-reset', data: {'email': email});
    } catch (e) {
      throw e.toString();
    }
  }

  Future<List<dynamic>> getActiveSessions() async {
    final response = await dio.get('/users/me/sessions');
    return response.data['data'];
  }

  Future<void> removeSession(String tokenId) async {
    try {
      await dio.delete('/users/me/sessions/$tokenId');
    } catch (e) {
      throw 'Failed to remove session: $e';
    }
  }
}