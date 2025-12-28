// profile_model.dart - Complete with all JobSeeker fields
import 'notification_preferences_model.dart';

// ============================================================================
// JOBSEEKER SPECIFIC MODELS
// ============================================================================

class SkillModel {
  final String name;
  final String level; // beginner, intermediate, advanced, expert

  SkillModel({
    required this.name,
    required this.level,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      name: json['name'] ?? '',
      level: json['level'] ?? 'beginner',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'level': level,
  };
}

class EducationModel {
  final String institution;
  final String degree;
  final String fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool current;
  final String? description;

  EducationModel({
    required this.institution,
    required this.degree,
    required this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.current = false,
    this.description,
  });

  factory EducationModel.fromJson(Map<String, dynamic> json) {
    return EducationModel(
      institution: json['institution'] ?? '',
      degree: json['degree'] ?? '',
      fieldOfStudy: json['fieldOfStudy'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      current: json['current'] ?? false,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'institution': institution,
    'degree': degree,
    'fieldOfStudy': fieldOfStudy,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    'current': current,
    if (description != null) 'description': description,
  };
}

class ExperienceModel {
  final String company;
  final String position;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool current;
  final String? description;
  final String? location;

  ExperienceModel({
    required this.company,
    required this.position,
    this.startDate,
    this.endDate,
    this.current = false,
    this.description,
    this.location,
  });

  factory ExperienceModel.fromJson(Map<String, dynamic> json) {
    return ExperienceModel(
      company: json['company'] ?? '',
      position: json['position'] ?? '',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      current: json['current'] ?? false,
      description: json['description'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() => {
    'company': company,
    'position': position,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    'current': current,
    if (description != null) 'description': description,
    if (location != null) 'location': location,
  };
}

class PreferencesModel {
  final List<String> jobTypes; // full-time, part-time, contract, internship, freelance
  final ExpectedSalaryModel? expectedSalary;
  final bool willingToRelocate;
  final DateTime? availableFrom;

  PreferencesModel({
    this.jobTypes = const [],
    this.expectedSalary,
    this.willingToRelocate = false,
    this.availableFrom,
  });

  factory PreferencesModel.fromJson(Map<String, dynamic> json) {
    return PreferencesModel(
      jobTypes: json['jobTypes'] != null
          ? List<String>.from(json['jobTypes'])
          : [],
      expectedSalary: json['expectedSalary'] != null
          ? ExpectedSalaryModel.fromJson(json['expectedSalary'])
          : null,
      willingToRelocate: json['willingToRelocate'] ?? false,
      availableFrom: json['availableFrom'] != null
          ? DateTime.parse(json['availableFrom'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'jobTypes': jobTypes,
    if (expectedSalary != null) 'expectedSalary': expectedSalary!.toJson(),
    'willingToRelocate': willingToRelocate,
    if (availableFrom != null) 'availableFrom': availableFrom!.toIso8601String(),
  };
}

class ExpectedSalaryModel {
  final int? min;
  final int? max;
  final String currency;

  ExpectedSalaryModel({
    this.min,
    this.max,
    this.currency = 'USD',
  });

  factory ExpectedSalaryModel.fromJson(Map<String, dynamic> json) {
    return ExpectedSalaryModel(
      min: json['min'],
      max: json['max'],
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() => {
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    'currency': currency,
  };
}

class JobSeekerProfileModel {
  final Map<String, dynamic>? resume;
  final List<SkillModel> skills;
  final List<EducationModel> education;
  final List<ExperienceModel> experience;
  final PreferencesModel? preferences;

  JobSeekerProfileModel({
    this.resume,
    this.skills = const [],
    this.education = const [],
    this.experience = const [],
    this.preferences,
  });

  factory JobSeekerProfileModel.fromJson(Map<String, dynamic> json) {
    return JobSeekerProfileModel(
      resume: json['resume'],
      skills: json['skills'] != null
          ? (json['skills'] as List).map((s) => SkillModel.fromJson(s)).toList()
          : [],
      education: json['education'] != null
          ? (json['education'] as List).map((e) => EducationModel.fromJson(e)).toList()
          : [],
      experience: json['experience'] != null
          ? (json['experience'] as List).map((e) => ExperienceModel.fromJson(e)).toList()
          : [],
      preferences: json['preferences'] != null
          ? PreferencesModel.fromJson(json['preferences'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (resume != null) 'resume': resume,
    'skills': skills.map((s) => s.toJson()).toList(),
    'education': education.map((e) => e.toJson()).toList(),
    'experience': experience.map((e) => e.toJson()).toList(),
    if (preferences != null) 'preferences': preferences!.toJson(),
  };
}

// ============================================================================
// MAIN PROFILE MODEL
// ============================================================================

class JobStatsModel {
  final int totalApplications;

  JobStatsModel({this.totalApplications = 0});

  factory JobStatsModel.fromJson(Map<String, dynamic> json) {
    return JobStatsModel(
      totalApplications: json['totalApplications'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'totalApplications': totalApplications};
}

class ProfileModel {
  final String id;
  final String email;
  final String role;
  final ProfileDetailsModel? profile;
  final JobSeekerProfileModel? jobSeekerProfile;
  final MarketplaceStatsModel? marketplaceStats;
  final JobStatsModel? jobStats;
  final NotificationPreferences? notificationPreferences;
  final PrivacySettings? privacySettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.email,
    required this.role,
    this.profile,
    this.jobSeekerProfile,
    this.marketplaceStats,
    this.jobStats,
    this.notificationPreferences,
    this.privacySettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['_id'] ?? json['id'],
      email: json['email'],
      role: json['role'],
      profile: json['profile'] != null
          ? ProfileDetailsModel.fromJson(json['profile'])
          : null,
      jobSeekerProfile: json['jobSeekerProfile'] != null
          ? JobSeekerProfileModel.fromJson(json['jobSeekerProfile'])
          : null,
      marketplaceStats: json['marketplaceStats'] != null
          ? MarketplaceStatsModel.fromJson(json['marketplaceStats'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      jobStats: json['jobStats'] != null
          ? JobStatsModel.fromJson(json['jobStats'])
          : null,
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(json['notificationPreferences'])
          : null,
      privacySettings: json['privacySettings'] != null
          ? PrivacySettings.fromJson(json['privacySettings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'role': role,
      'profile': profile?.toJson(),
      'jobSeekerProfile': jobSeekerProfile?.toJson(),
      'marketplaceStats': marketplaceStats?.toJson(),
      'notificationPreferences': notificationPreferences?.toJson(),
      'privacySettings': privacySettings?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// ============================================================================
// SUPPORTING MODELS
// ============================================================================

class PrivacySettings {
  final String profileVisibility;
  final bool showEmail;
  final bool showPhone;
  final bool biometricLogin;

  PrivacySettings({
    required this.profileVisibility,
    required this.showEmail,
    required this.showPhone,
    required this.biometricLogin,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisibility: json['profileVisibility'] ?? 'public',
      showEmail: json['showEmail'] ?? false,
      showPhone: json['showPhone'] ?? false,
      biometricLogin: json['biometricLogin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVisibility': profileVisibility,
      'showEmail': showEmail,
      'showPhone': showPhone,
      'biometricLogin': biometricLogin,
    };
  }

  PrivacySettings copyWith({
    String? profileVisibility,
    bool? showEmail,
    bool? showPhone,
    bool? biometricLogin,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      biometricLogin: biometricLogin ?? this.biometricLogin,
    );
  }
}

class ProfileDetailsModel {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? bio;
  final String? avatar;
  final ProfileLocationModel? location;

  ProfileDetailsModel({
    this.firstName,
    this.lastName,
    this.phone,
    this.bio,
    this.avatar,
    this.location,
  });

  String get displayName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return 'User';
    return '$first $last'.trim();
  }

  String get initials {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return 'U';
    final firstInitial = first.isNotEmpty ? first[0] : '';
    final lastInitial = last.isNotEmpty ? last[0] : '';
    return '$firstInitial$lastInitial'.toUpperCase();
  }

  factory ProfileDetailsModel.fromJson(Map<String, dynamic> json) {
    return ProfileDetailsModel(
      firstName: json['firstName'],
      lastName: json['lastName'],
      phone: json['phone'],
      bio: json['bio'],
      avatar: json['avatar'],
      location: json['location'] != null
          ? ProfileLocationModel.fromJson(json['location'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'bio': bio,
      'avatar': avatar,
      'location': location?.toJson(),
    };
  }
}

class ProfileLocationModel {
  final String? city;
  final String? state;
  final String? country;

  ProfileLocationModel({this.city, this.state, this.country});

  factory ProfileLocationModel.fromJson(Map<String, dynamic> json) {
    return ProfileLocationModel(
      city: json['city'],
      state: json['state'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'state': state,
      'country': country,
    };
  }
}

class MarketplaceStatsModel {
  final int productsPosted;
  final int activeProducts;
  final int totalViews;
  final SellerRatingModel? sellerRating;

  MarketplaceStatsModel({
    this.productsPosted = 0,
    this.activeProducts = 0,
    this.totalViews = 0,
    this.sellerRating,
  });

  factory MarketplaceStatsModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceStatsModel(
      productsPosted: json['productsPosted'] ?? 0,
      activeProducts: json['activeProducts'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      sellerRating: json['sellerRating'] != null
          ? SellerRatingModel.fromJson(json['sellerRating'])
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

class SellerRatingModel {
  final double average;
  final int count;

  SellerRatingModel({
    this.average = 0.0,
    this.count = 0,
  });

  factory SellerRatingModel.fromJson(Map<String, dynamic> json) {
    return SellerRatingModel(
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