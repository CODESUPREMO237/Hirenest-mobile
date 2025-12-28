// ============================================================================
// job_model.dart (FIXED)
// lib/features/jobs/data/models/job_model.dart
// ============================================================================

class JobModel {
  final String id;
  final String title;
  final String postedBy;
  final String description;
  final String jobType;
  final String category;
  final String experienceLevel;
  final CompanyModel company;
  final JobLocationModel location;
  final SalaryModel? salary;
  final RequirementsModel requirements;
  final List<String> benefits;
  final String status;
  final DateTime? applicationDeadline;
  final JobStatsModel? stats;  // ✅ Added stats object
  final bool isApplied;
  final List<ScreeningQuestionModel>? screeningQuestions; // ✅ ADD THIS

  final DateTime createdAt;
  final DateTime updatedAt;

  JobModel({
    required this.id,
    required this.title,
    required this.postedBy,
    required this.description,
    required this.jobType,
    required this.category,
    required this.experienceLevel,
    required this.company,
    required this.location,
    this.salary,
    required this.requirements,
    required this.benefits,
    required this.status,
    this.applicationDeadline,
    this.stats,  // ✅ Added stats
    this.isApplied = false,
    this.screeningQuestions, // ✅ ADD THIS

    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ Convenience getters for backward compatibility
  int get applicantsCount => stats?.applications ?? 0;
  int get views => stats?.views ?? 0;
  int get uniqueViews => stats?.uniqueViews ?? 0;


  factory JobModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely extract IDs from either Strings or nested Objects
    String extractId(dynamic data) {
      if (data == null) return '';
      if (data is String) return data;
      if (data is Map) {
        return data['_id']?.toString() ?? data['id']?.toString() ?? '';
      }
      return '';
    }

    return JobModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      postedBy: extractId(json['postedBy']),
      description: json['description'] ?? '',
      jobType: json['jobType'] ?? '',
      category: json['category'] ?? '',
      experienceLevel: json['experienceLevel'] ?? '',

      // FIX: Check if company is a Map before parsing, otherwise provide a dummy/empty model
      company: json['company'] is Map<String, dynamic>
          ? CompanyModel.fromJson(json['company'])
          : CompanyModel(id: extractId(json['company']), name: 'Loading...'),

      // FIX: Defensive parsing for Location
      location: json['location'] is Map<String, dynamic>
          ? JobLocationModel.fromJson(json['location'])
          : JobLocationModel(type: 'onsite', address: AddressModel(city: '', country: '')),

      salary: json['salary'] != null ? SalaryModel.fromJson(json['salary']) : null,

      // FIX: Defensive parsing for Requirements
      requirements: json['requirements'] is Map<String, dynamic>
          ? RequirementsModel.fromJson(json['requirements'])
          : RequirementsModel(skills: [], yearsOfExperience: YearsOfExperienceModel(min: 0)),

      benefits: List<String>.from(json['benefits'] ?? []),
      status: json['status'] ?? 'active',
      applicationDeadline: json['applicationDeadline'] != null
          ? DateTime.parse(json['applicationDeadline'])
          : null,
      stats: json['stats'] != null
          ? JobStatsModel.fromJson(json['stats'])
          : null,
      isApplied: json['isApplied'] ?? false,
      // ✅ Parse screening questions
      screeningQuestions: json['screeningQuestions'] != null
          ? (json['screeningQuestions'] as List)
          .map((q) => ScreeningQuestionModel.fromJson(q))
          .toList()
          : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'postedBy': postedBy,
      'description': description,
      'jobType': jobType,
      'category': category,
      'experienceLevel': experienceLevel,
      'company': company.toJson(),
      'location': location.toJson(),
      'salary': salary?.toJson(),
      'requirements': requirements.toJson(),
      'benefits': benefits,
      'status': status,
      'applicationDeadline': applicationDeadline?.toIso8601String(),
      'stats': stats?.toJson(),
      'isApplied': isApplied,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
// ✅ ADD THIS NEW MODEL CLASS
class ScreeningQuestionModel {
  final String question;
  final String type; // 'text', 'yes_no', 'multiple_choice'
  final bool required;
  final List<String>? options; // For multiple_choice type

  ScreeningQuestionModel({
    required this.question,
    required this.type,
    this.required = false,
    this.options,
  });

  factory ScreeningQuestionModel.fromJson(Map<String, dynamic> json) {
    return ScreeningQuestionModel(
      question: json['question'] ?? '',
      type: json['type'] ?? 'text',
      required: json['required'] ?? false,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'type': type,
      'required': required,
      if (options != null) 'options': options,
    };
  }
}


class JobStatsModel {
  final int views;
  final int uniqueViews;
  final int applications;

  JobStatsModel({
    required this.views,
    required this.uniqueViews,
    required this.applications,
  });

  factory JobStatsModel.fromJson(Map<String, dynamic> json) {
    // Helper to force anything into an int safely
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return JobStatsModel(
      views: toInt(json['views']),
      uniqueViews: toInt(json['uniqueViews']),
      applications: toInt(json['applications']),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'views': views,
      'uniqueViews': uniqueViews,
      'applications': applications,
    };
  }
}

class CompanyModel {
  final String id;
  final String name;
  final String? logo;

  CompanyModel({required this.id, required this.name, this.logo});

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'logo': logo,
    };
  }
}

class JobLocationModel {
  final String type;
  final AddressModel? address;

  JobLocationModel({required this.type, this.address});

  factory JobLocationModel.fromJson(Map<String, dynamic> json) {
    return JobLocationModel(
      type: json['type'],
      address: json['address'] != null ? AddressModel.fromJson(json['address']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'address': address?.toJson(),
    };
  }
}

class AddressModel {
  final String? city;
  final String? state;
  final String? country;

  AddressModel({this.city, this.state, this.country});

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
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

class SalaryModel {
  final double? min;
  final double? max;
  final String currency;
  final String period;
  final bool showSalary;

  SalaryModel({
    this.min,
    this.max,
    required this.currency,
    required this.period,
    required this.showSalary,
  });

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    double? toDoubleSafe(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return SalaryModel(
      min: toDoubleSafe(json['min']),
      max: toDoubleSafe(json['max']),
      currency: json['currency'] ?? '\$',
      period: json['period'] ?? 'monthly',
      showSalary: json['showSalary'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'currency': currency,
      'period': period,
      'showSalary': showSalary,
    };
  }
}

class RequirementsModel {
  final List<SkillModel> skills;
  final YearsOfExperienceModel? yearsOfExperience;

  RequirementsModel({required this.skills, this.yearsOfExperience});

  factory RequirementsModel.fromJson(Map<String, dynamic> json) {
    return RequirementsModel(
      skills: (json['skills'] as List?)
          ?.map((s) => SkillModel.fromJson(s))
          .toList() ??
          [],
      yearsOfExperience: json['yearsOfExperience'] != null
          ? YearsOfExperienceModel.fromJson(json['yearsOfExperience'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skills': skills.map((s) => s.toJson()).toList(),
      'yearsOfExperience': yearsOfExperience?.toJson(),
    };
  }
}

class SkillModel {
  final String name;
  final bool required;
  final String? level;

  SkillModel({required this.name, required this.required, this.level});

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      name: json['name'],
      required: json['required'] ?? false,
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'required': required,
      'level': level,
    };
  }
}

class YearsOfExperienceModel {
  final int? min;
  final int? max;

  YearsOfExperienceModel({this.min, this.max});

  factory YearsOfExperienceModel.fromJson(Map<String, dynamic> json) {
    int? toIntSafe(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return YearsOfExperienceModel(
      min: toIntSafe(json['min']),
      max: toIntSafe(json['max']),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}