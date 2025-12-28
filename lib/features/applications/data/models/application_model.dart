// lib/features/applications/data/models/application_model.dart

import 'dart:convert';

import '../../../jobs/data/models/job_model.dart';
import '../../../auth/data/models/user_model.dart';

class ApplicationModel {
  final String id;
  final String job;
  final String applicant;
  final String? coverLetter;
  final ResumeData? resume;
  final List<ScreeningAnswer>? screeningAnswers;
  final Map<String, dynamic>? additionalInfo;
  final String status;
  final bool isViewed;
  final DateTime? viewedAt;
  final DateTime? appliedAt;
  final String? employerNotes;
  final int? employerRating;
  final List<InterviewData>? interviews;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String? rejectionFeedback;
  final DateTime? withdrawnAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  // Populated fields
  final JobModel? jobDetails;
  final UserModel? applicantDetails;

  ApplicationModel({
    required this.id,
    required this.job,
    required this.applicant,
    this.coverLetter,
    this.resume,
    this.screeningAnswers,
    this.additionalInfo,
    this.status = 'pending',
    this.isViewed = false,
    this.viewedAt,
    this.appliedAt,
    this.employerNotes,
    this.employerRating,
    this.interviews,
    this.rejectedAt,
    this.rejectionReason,
    this.rejectionFeedback,
    this.withdrawnAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.jobDetails,
    this.applicantDetails,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    // 🔥 DEBUG: Print what we're receiving
    print('');
    print('═══════════════════════════════════════════════════');
    print('🔍 APPLICATION MODEL PARSING STARTED');
    print('═══════════════════════════════════════════════════');
    print('Application ID: ${json['_id'] ?? json['id']}');
    print('Job field type: ${json['job'].runtimeType}');
    print('Job field is Map?: ${json['job'] is Map}');
    print('Job field value: ${json['job']}');
    print('');

    int? tryParseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString());
    }

    // Parse jobDetails
    JobModel? parsedJobDetails;
    String extractedJobId = '';

    if (json['job'] is Map<String, dynamic>) {
      print('✅ Job is a Map - attempting to parse JobModel...');
      extractedJobId = json['job']['_id']?.toString() ?? json['job']['id']?.toString() ?? '';
      print('   Extracted Job ID: $extractedJobId');

      try {
        parsedJobDetails = JobModel.fromJson(json['job']);
        print('✅ JobModel parsed successfully!');
        print('   Job Title: "${parsedJobDetails.title}"');
        print('   Job ID: ${parsedJobDetails.id}');
        print('   Company: ${parsedJobDetails.company.name}');
      } catch (e, stackTrace) {
        print('❌ ERROR parsing JobModel:');
        print('   Error: $e');
        print('   Stack trace: $stackTrace');
      }
    } else if (json['job'] is String) {
      extractedJobId = json['job'];
      print('⚠️  Job is a String (just ID): $extractedJobId');
      print('   JobDetails will be NULL');
    } else {
      print('❌ Job is neither Map nor String - it\'s: ${json['job'].runtimeType}');
    }

    print('');
    print('📋 Other Application Fields:');
    print('   Status: ${json['status']}');
    print('   Applied At: ${json['appliedAt']}');
    print('   Cover Letter: ${json['coverLetter'] != null ? "Present" : "NULL"}');
    print('   Resume: ${json['resume'] != null ? "Present" : "NULL"}');
    print('═══════════════════════════════════════════════════');
    print('');

    return ApplicationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',

      // Handles both populated objects and ID strings
      job: extractedJobId,

      applicant: json['applicant'] is Map
          ? json['applicant']['_id']?.toString() ?? ''
          : json['applicant']?.toString() ?? '',

      coverLetter: json['coverLetter']?.toString(),

      resume: json['resume'] != null && json['resume'] is Map<String, dynamic>
          ? ResumeData.fromJson(json['resume'])
          : null,

      status: json['status']?.toString() ?? 'pending',
      isViewed: json['isViewed'] ?? false,
      viewedAt: json['viewedAt'] != null ? DateTime.parse(json['viewedAt']) : null,

      appliedAt: json['appliedAt'] != null
          ? DateTime.parse(json['appliedAt'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null),

      employerNotes: json['employerNotes']?.toString(),
      employerRating: tryParseInt(json['employerRating']),

      interviews: (json['interviews'] as List?)
          ?.map((i) => InterviewData.fromJson(i))
          .toList(),

      rejectedAt: json['rejectedAt'] != null ? DateTime.parse(json['rejectedAt']) : null,
      rejectionReason: json['rejectionReason']?.toString(),
      rejectionFeedback: json['rejectionFeedback']?.toString(),
      withdrawnAt: json['withdrawnAt'] != null ? DateTime.parse(json['withdrawnAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,

      // Populated fields
      jobDetails: parsedJobDetails,

      applicantDetails: json['applicant'] is Map<String, dynamic>
          ? UserModel.fromJson(json['applicant'])
          : null,

      // SAFER SCREENING ANSWERS
      screeningAnswers: json['screeningAnswers'] == null
          ? null
          : (json['screeningAnswers'] is String
          ? (jsonDecode(json['screeningAnswers']) as List)
          : (json['screeningAnswers'] as List))
          .map((a) => ScreeningAnswer.fromJson(a))
          .toList(),

      // SAFER ADDITIONAL INFO
      additionalInfo: json['additionalInfo'] == null
          ? null
          : (json['additionalInfo'] is String
          ? jsonDecode(json['additionalInfo']) as Map<String, dynamic>
          : json['additionalInfo'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job': job,
      'applicant': applicant,
      'coverLetter': coverLetter,
      'resume': resume?.toJson(),
      'screeningAnswers': screeningAnswers?.map((a) => a.toJson()).toList(),
      'additionalInfo': additionalInfo,
      'status': status,
      'isViewed': isViewed,
      'viewedAt': viewedAt?.toIso8601String(),
      'appliedAt': appliedAt?.toIso8601String(),
      'employerNotes': employerNotes,
      'employerRating': employerRating,
      'interviews': interviews?.map((i) => i.toJson()).toList(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'rejectionFeedback': rejectionFeedback,
      'withdrawnAt': withdrawnAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // Get applicant info (handles both populated and non-populated)
  UserModel? get applicantInfo => applicantDetails;

  // Get job info (handles both populated and non-populated)
  JobModel? get jobInfo => jobDetails;

  // Check if application can be withdrawn
  bool get canWithdraw {
    return !['accepted', 'rejected', 'withdrawn'].contains(status);
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'reviewing':
        return 'blue';
      case 'shortlisted':
        return 'purple';
      case 'interviewing':
        return 'indigo';
      case 'offered':
        return 'teal';
      case 'accepted':
        return 'green';
      case 'rejected':
        return 'red';
      case 'withdrawn':
        return 'grey';
      default:
        return 'grey';
    }
  }

  // Get status display text
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'reviewing':
        return 'Under Review';
      case 'shortlisted':
        return 'Shortlisted';
      case 'interviewing':
        return 'Interview Scheduled';
      case 'offered':
        return 'Offer Extended';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Not Selected';
      case 'withdrawn':
        return 'Withdrawn';
      default:
        return status;
    }
  }

  // CopyWith method for immutability
  ApplicationModel copyWith({
    String? id,
    String? job,
    String? applicant,
    String? coverLetter,
    ResumeData? resume,
    List<ScreeningAnswer>? screeningAnswers,
    Map<String, dynamic>? additionalInfo,
    String? status,
    bool? isViewed,
    DateTime? viewedAt,
    DateTime? appliedAt,
    String? employerNotes,
    int? employerRating,
    List<InterviewData>? interviews,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? rejectionFeedback,
    DateTime? withdrawnAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    JobModel? jobDetails,
    UserModel? applicantDetails,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      job: job ?? this.job,
      applicant: applicant ?? this.applicant,
      coverLetter: coverLetter ?? this.coverLetter,
      resume: resume ?? this.resume,
      screeningAnswers: screeningAnswers ?? this.screeningAnswers,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      status: status ?? this.status,
      isViewed: isViewed ?? this.isViewed,
      viewedAt: viewedAt ?? this.viewedAt,
      appliedAt: appliedAt ?? this.appliedAt,
      employerNotes: employerNotes ?? this.employerNotes,
      employerRating: employerRating ?? this.employerRating,
      interviews: interviews ?? this.interviews,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectionFeedback: rejectionFeedback ?? this.rejectionFeedback,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      jobDetails: jobDetails ?? this.jobDetails,
      applicantDetails: applicantDetails ?? this.applicantDetails,
    );
  }
}

class ResumeData {
  final String url;
  final String? filename;
  final String? publicId;
  final int? size;

  ResumeData({
    required this.url,
    this.filename,
    this.publicId,
    this.size,
  });

  factory ResumeData.fromJson(Map<String, dynamic> json) {
    return ResumeData(
      url: json['url']?.toString() ?? '',
      filename: json['filename']?.toString(),
      publicId: json['publicId']?.toString(),
      size: json['size'] is int
          ? json['size']
          : int.tryParse(json['size']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'filename': filename,
      'publicId': publicId,
      'size': size,
    };
  }
}

class ScreeningAnswer {
  final String question;
  final String answer;

  ScreeningAnswer({
    required this.question,
    required this.answer,
  });

  factory ScreeningAnswer.fromJson(Map<String, dynamic> json) {
    return ScreeningAnswer(
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}

class InterviewData {
  final DateTime scheduledAt;
  final String? location;
  final String? meetingLink;
  final String? notes;
  final String? type;
  final String? status;
  final DateTime? completedAt;
  final String? feedback;

  InterviewData({
    required this.scheduledAt,
    this.location,
    this.meetingLink,
    this.notes,
    this.type,
    this.status,
    this.completedAt,
    this.feedback,
  });

  factory InterviewData.fromJson(Map<String, dynamic> json) {
    return InterviewData(
      scheduledAt: DateTime.parse(json['scheduledAt']),
      location: json['location']?.toString(),
      meetingLink: json['meetingLink']?.toString(),
      notes: json['notes']?.toString(),
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      feedback: json['feedback']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduledAt': scheduledAt.toIso8601String(),
      'location': location,
      'meetingLink': meetingLink,
      'notes': notes,
      'type': type,
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
      'feedback': feedback,
    };
  }
}