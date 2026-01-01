// Company Model
// lib/features/company/data/models/company_model.dart
import '../../../auth/data/models/user_model.dart';

class CompanyModel {
  final String id;
  final String name;
  final String? description;
  final String? industry;
  final String? companySize;
  final String? logo;
  final String? banner;
  final String? website;
  final String? email;
  final String? contactPhone;
  final List<Location>? locations;
  final CompanyStats? stats;
  final List<UserModel> admins;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyModel({
    required this.id,
    required this.name,
    this.description,
    this.industry,
    this.companySize,
    this.logo,
    this.banner,
    this.website,
    this.email,
    this.contactPhone,
    this.locations,
    this.stats,
    required this.admins,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      industry: json['industry'],
      companySize: json['companySize'],
      logo: json['logo'],
      banner: json['banner'],
      website: json['website'],
      email: json['email'],
      contactPhone: json['contactPhone'],
      locations: json['locations'] != null
          ? (json['locations'] as List)
          .map((l) => Location.fromJson(l))
          .toList()
          : null,
      stats: json['stats'] != null ? CompanyStats.fromJson(json['stats']) : null,

      // Updated Admins Logic
      admins: json['admins'] != null
          ? (json['admins'] as List).map((adminData) {
        if (adminData is String) {
          // Handle case where it's just an ID string
          return UserModel(
            id: adminData,
            email: '',
            role: 'user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        } else if (adminData is Map<String, dynamic>) {
          // Handle case where it's the full object (from your log)
          return UserModel.fromJson(adminData);
        }
        return UserModel.empty();
      }).toList()
          : [],

      // FIX: Handle createdBy similarly
      createdBy: json['createdBy'] is String
          ? json['createdBy']
          : (json['createdBy']?['_id']?.toString() ?? ''),

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class Location {
  final String city;
  final String? state;
  final String country;
  final String? address;

  Location({
    required this.city,
    this.state,
    required this.country,
    this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      city: json['city'] ?? '',
      state: json['state'],
      country: json['country'] ?? '',
      address: json['address'],
    );
  }
}

class CompanyStats {
  final int activeJobs;
  final int totalEmployees;
  final double? averageRating;

  CompanyStats({
    required this.activeJobs,
    required this.totalEmployees,
    this.averageRating,
  });

  factory CompanyStats.fromJson(Map<String, dynamic> json) {
    return CompanyStats(
      activeJobs: json['activeJobs'] ?? 0,
      totalEmployees: json['totalEmployees'] ?? 0,
      // Handle potential int/double mismatch from JSON
      averageRating: json['averageRating']?.toDouble(),
    );
  }
}