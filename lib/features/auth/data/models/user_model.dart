// User Model
// ============================================================================
// user_model.dart
// lib/features/auth/data/models/user_model.dart
// ============================================================================

import '../../../../core/utils/logger.dart';

class UserModel {
  final String id;
  final String email;
  final String role;
  final ProfileData? profile;
  final JobSeekerProfileData? jobSeekerProfile;
  final EmployerProfileData? employerProfile;
  final MarketplaceStatsData? marketplaceStats;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.profile,
    this.jobSeekerProfile,
    this.employerProfile,
    this.marketplaceStats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      // 1. Extract IDs safely (handles both _id and id)
      final String id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

      // 2. Extract Dates safely (handles null or invalid date strings)
      DateTime parseDate(dynamic dateStr) {
        if (dateStr == null) return DateTime.now();
        try {
          return DateTime.parse(dateStr.toString());
        } catch (_) {
          return DateTime.now();
        }
      }

      final model = UserModel(
        id: id,
        // Use ?.toString() ?? '' to prevent "Null is not a subtype of String"
        email: json['email']?.toString() ?? '',
        role: json['role']?.toString() ?? 'user',

        profile: json['profile'] != null && json['profile'] is Map<String, dynamic>
            ? ProfileData.fromJson(json['profile'] as Map<String, dynamic>)
            : null,

        jobSeekerProfile: json['jobSeekerProfile'] != null && json['jobSeekerProfile'] is Map<String, dynamic>
            ? JobSeekerProfileData.fromJson(json['jobSeekerProfile'] as Map<String, dynamic>)
            : null,

        employerProfile: json['employerProfile'] != null && json['employerProfile'] is Map<String, dynamic>
            ? EmployerProfileData.fromJson(json['employerProfile'] as Map<String, dynamic>)
            : null,

        marketplaceStats: json['marketplaceStats'] != null && json['marketplaceStats'] is Map<String, dynamic>
            ? MarketplaceStatsData.fromJson(json['marketplaceStats'] as Map<String, dynamic>)
            : null,

        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
      );

      return model;
    } catch (e, stack) {
      AppLogger.error('Critical Error parsing UserModel', error: e, stackTrace: stack);
      // Instead of rethrowing and crashing the UI, return a fallback model
      return UserModel.empty();
    }
  }
  factory UserModel.empty() {
    return UserModel(
      id: '',
      email: '',
      role: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'profile': profile?.toJson(),
      'jobSeekerProfile': jobSeekerProfile?.toJson(),
      'employerProfile': employerProfile?.toJson(),
      'marketplaceStats': marketplaceStats?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Computed property for full name
  String get fullName {
    if (profile?.firstName != null && profile?.lastName != null) {
      return '${profile!.firstName} ${profile!.lastName}';
    }
    return profile?.displayName ?? email.split('@')[0];
  }

  // Computed property for display name
  String get displayName {
    if (profile?.displayName != null && profile!.displayName!.isNotEmpty) {
      return profile!.displayName!;
    }
    return fullName;
  }
}

class ProfileData {
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? phone;
  final String? bio;
  final String? avatar;
  final String? headline;
  final LocationData? location;

  ProfileData({
    this.firstName,
    this.lastName,
    this.displayName,
    this.phone,
    this.bio,
    this.avatar,
    this.headline,
    this.location,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.debug('Parsing ProfileData from JSON');
      AppLogger.debug('Profile JSON: $json');

      return ProfileData(
        // Using ?.toString() ensures we never pass 'null' to a String field
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        displayName: json['displayName']?.toString(),
        phone: json['phone']?.toString(),
        bio: json['bio']?.toString(),
        avatar: json['avatar']?.toString(),
        headline: json['headline']?.toString(),
        location: json['location'] != null
            ? LocationData.fromJson(json['location'] as Map<String, dynamic>)
            : null,
      );
    } catch (e, stack) {
      AppLogger.error('Error parsing ProfileData', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'phone': phone,
      'bio': bio,
      'avatar': avatar,
      'headline': headline,
      'location': location?.toJson(),
    };
  }
}

class LocationData {
  final String? city;
  final String? state;
  final String? country;
  final CoordinatesData? coordinates;

  LocationData({
    this.city,
    this.state,
    this.country,
    this.coordinates,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    try {
      return LocationData(
        city: json['city'],
        state: json['state'],
        country: json['country'],
        coordinates: json['coordinates'] != null
            ? CoordinatesData.fromJson(json['coordinates'])
            : null,
      );
    } catch (e, stack) {
      AppLogger.error('Error parsing LocationData', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'state': state,
      'country': country,
      'coordinates': coordinates?.toJson(),
    };
  }
}

class CoordinatesData {
  final String type;
  final List<double> coordinates;

  CoordinatesData({
    required this.type,
    required this.coordinates,
  });

  factory CoordinatesData.fromJson(Map<String, dynamic> json) {
    return CoordinatesData(
      type: json['type'] ?? 'Point',
      coordinates: (json['coordinates'] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList() ?? [0.0, 0.0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}

class JobSeekerProfileData {
  final ResumeData? resume;
  final List<ExperienceData>? experience;
  final List<EducationData>? education;
  final List<SkillData>? skills;
  final PreferencesData? preferences;
  final StatsData? stats;

  JobSeekerProfileData({
    this.resume,
    this.experience,
    this.education,
    this.skills,
    this.preferences,
    this.stats,
  });

  factory JobSeekerProfileData.fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.debug('Parsing JobSeekerProfileData');

      return JobSeekerProfileData(
        resume: json['resume'] != null
            ? ResumeData.fromJson(json['resume'])
            : null,
        experience: (json['experience'] as List?)
            ?.map((e) => ExperienceData.fromJson(e as Map<String, dynamic>))
            .toList(),
        education: (json['education'] as List?)
            ?.map((e) => EducationData.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: (json['skills'] as List?)
            ?.map((e) => SkillData.fromJson(e is Map<String, dynamic> ? e : {'name': e.toString()}))
            .toList(),
        preferences: json['preferences'] != null
            ? PreferencesData.fromJson(json['preferences'])
            : null,
        stats: json['stats'] != null
            ? StatsData.fromJson(json['stats'])
            : null,
      );
    } catch (e, stack) {
      AppLogger.error('Error parsing JobSeekerProfileData', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'resume': resume?.toJson(),
      'experience': experience?.map((e) => e.toJson()).toList(),
      'education': education?.map((e) => e.toJson()).toList(),
      'skills': skills?.map((e) => e.toJson()).toList(),
      'preferences': preferences?.toJson(),
      'stats': stats?.toJson(),
    };
  }
}

class ResumeData {
  final String? url;
  final String? filename;
  final DateTime? uploadedAt;

  ResumeData({this.url, this.filename, this.uploadedAt});

  factory ResumeData.fromJson(Map<String, dynamic> json) {
    return ResumeData(
      url: json['url'],
      filename: json['filename'],
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'filename': filename,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }
}

class SkillData {
  final String? name;
  final String? level;

  SkillData({this.name, this.level});

  factory SkillData.fromJson(Map<String, dynamic> json) {
    return SkillData(
      name: json['name'],
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'level': level,
    };
  }
}

class PreferencesData {
  final List<String>? jobTypes;
  final SalaryData? expectedSalary;
  final bool? willingToRelocate;
  final DateTime? availableFrom;

  PreferencesData({
    this.jobTypes,
    this.expectedSalary,
    this.willingToRelocate,
    this.availableFrom,
  });

  factory PreferencesData.fromJson(Map<String, dynamic> json) {
    return PreferencesData(
      jobTypes: (json['jobTypes'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      expectedSalary: json['expectedSalary'] != null
          ? SalaryData.fromJson(json['expectedSalary'])
          : null,
      willingToRelocate: json['willingToRelocate'],
      availableFrom: json['availableFrom'] != null
          ? DateTime.parse(json['availableFrom'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobTypes': jobTypes,
      'expectedSalary': expectedSalary?.toJson(),
      'willingToRelocate': willingToRelocate,
      'availableFrom': availableFrom?.toIso8601String(),
    };
  }
}

class SalaryData {
  final double? min;
  final double? max;
  final String currency;

  SalaryData({
    this.min,
    this.max,
    required this.currency,
  });

  factory SalaryData.fromJson(Map<String, dynamic> json) {
    return SalaryData(
      min: json['min']?.toDouble(),
      max: json['max']?.toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'currency': currency,
    };
  }
}

class StatsData {
  final int appliedJobs;
  final int savedJobs;
  final int profileViews;

  StatsData({
    required this.appliedJobs,
    required this.savedJobs,
    required this.profileViews,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    return StatsData(
      appliedJobs: json['appliedJobs'] ?? 0,
      savedJobs: json['savedJobs'] ?? 0,
      profileViews: json['profileViews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appliedJobs': appliedJobs,
      'savedJobs': savedJobs,
      'profileViews': profileViews,
    };
  }
}

class ExperienceData {
  final String? position;
  final String? company;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? current;
  final String? description;
  final String? location;

  ExperienceData({
    this.position,
    this.company,
    this.startDate,
    this.endDate,
    this.current,
    this.description,
    this.location,
  });

  factory ExperienceData.fromJson(Map<String, dynamic> json) {
    return ExperienceData(
      position: json['position'],
      company: json['company'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      current: json['current'] ?? json['isCurrent'],
      description: json['description'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'company': company,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'current': current,
      'description': description,
      'location': location,
    };
  }
}

class EducationData {
  final String? degree;
  final String? institution;
  final String? fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? current;
  final String? description;

  EducationData({
    this.degree,
    this.institution,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.current,
    this.description,
  });

  // --- FIX: ADD THESE GETTERS ---
  String? get startYear => startDate != null ? startDate!.year.toString() : null;
  String? get endYear => endDate != null ? endDate!.year.toString() : null;
  // ------------------------------

  factory EducationData.fromJson(Map<String, dynamic> json) {
    return EducationData(
      degree: json['degree'],
      institution: json['institution'],
      fieldOfStudy: json['fieldOfStudy'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      current: json['current'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'degree': degree,
      'institution': institution,
      'fieldOfStudy': fieldOfStudy,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'current': current,
      'description': description,
    };
  }
}

class EmployerProfileData {
  final String? company;
  final String? position;
  final String? department;
  final bool verified;
  final EmployerStatsData? stats;

  EmployerProfileData({
    this.company,
    this.position,
    this.department,
    required this.verified,
    this.stats,
  });

  factory EmployerProfileData.fromJson(Map<String, dynamic> json) {
    return EmployerProfileData(
      // New way - Safe parsing
      company: json['company'] is Map
          ? json['company']['_id'] ?? json['company']['id'] // Extract ID if it's a Map
          : json['company'], // Keep as String if it's just an ID
      position: json['position'],
      department: json['department'],
      verified: json['verified'] ?? false,
      stats: json['stats'] != null
          ? EmployerStatsData.fromJson(json['stats'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'position': position,
      'department': department,
      'verified': verified,
      'stats': stats?.toJson(),
    };
  }
}

class EmployerStatsData {
  final int jobsPosted;
  final int activeJobs;
  final int totalApplicants;
  final int hiredCandidates;

  EmployerStatsData({
    required this.jobsPosted,
    required this.activeJobs,
    required this.totalApplicants,
    required this.hiredCandidates,
  });

  factory EmployerStatsData.fromJson(Map<String, dynamic> json) {
    return EmployerStatsData(
      jobsPosted: json['jobsPosted'] ?? 0,
      activeJobs: json['activeJobs'] ?? 0,
      totalApplicants: json['totalApplicants'] ?? 0,
      hiredCandidates: json['hiredCandidates'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobsPosted': jobsPosted,
      'activeJobs': activeJobs,
      'totalApplicants': totalApplicants,
      'hiredCandidates': hiredCandidates,
    };
  }
}

class MarketplaceStatsData {
  final int productsPosted;
  final int activeProducts;
  final int totalViews;
  final RatingData? sellerRating;

  MarketplaceStatsData({
    required this.productsPosted,
    required this.activeProducts,
    required this.totalViews,
    this.sellerRating,
  });

  factory MarketplaceStatsData.fromJson(Map<String, dynamic> json) {
    return MarketplaceStatsData(
      productsPosted: json['productsPosted'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      sellerRating: json['sellerRating'] != null
          ? RatingData.fromJson(json['sellerRating'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productsPosted': productsPosted,
      'activeProducts': activeProducts,
      'totalViews': totalViews,
      'sellerRating': sellerRating?.toJson(),
    };
  }
}

class RatingData {
  final double average;
  final int count;

  RatingData({
    required this.average,
    required this.count,
  });

  factory RatingData.fromJson(Map<String, dynamic> json) {
    return RatingData(
      average: (json['average'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average': average,
      'count': count,
    };
  }
}