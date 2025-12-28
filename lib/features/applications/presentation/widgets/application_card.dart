// lib/features/Application/presentation/widgets/application_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/application_model.dart';
import '../../../../core/theme/app_colors.dart';

class ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  final VoidCallback? onTap;
  final bool isEmployerView;

  const ApplicationCard({
    super.key,
    required this.application,
    this.onTap,
    this.isEmployerView = false,
  });

  @override
  Widget build(BuildContext context) {
    // Extract the data verified by your logs
    final job = application.jobInfo;
    final String displayTitle = job?.title ?? 'Position Applied';

    // Extracting Company and City from the nested JobModel
    final String companyName = job?.company.name ?? 'Company N/A';
    final String city = job?.location.address?.city ?? 'Location N/A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE AND STATUS ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(application.status),
                ],
              ),

              // ✅ CONDITIONAL DISPLAY: Show different info for employer vs job seeker
              if (isEmployerView) ...[
                // EMPLOYER VIEW: Show applicant name
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _getApplicantName(),
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // JOB SEEKER VIEW: Show company name
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    companyName,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],

              const Divider(height: 16),

              // LOCATION AND DATE ROW
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    city,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    application.appliedAt != null
                        ? DateFormat('MMM dd, yyyy').format(application.appliedAt!)
                        : 'N/A',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),

              // SALARY SECTION
              if (_hasExpectedSalary(application.additionalInfo)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      _getExpectedSalaryText(application.additionalInfo?['expectedSalary']),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  String _getApplicantName() {
    // ✅ FIXED: Use applicantDetails (UserModel) instead of applicant (String)
    final applicantDetails = application.applicantDetails;

    if (applicantDetails == null) {
      return 'Applicant';
    }

    // ✅ CORRECT: firstName and lastName are in ProfileData, not JobSeekerProfileData
    final profile = applicantDetails.profile;
    if (profile != null) {
      final firstName = profile.firstName ?? '';
      final lastName = profile.lastName ?? '';
      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) {
        return fullName;
      }

      // Try display name if full name is empty
      if (profile.displayName != null && profile.displayName!.isNotEmpty) {
        return profile.displayName!;
      }
    }

    // Fallback to email (split at @ to get username part)
    if (applicantDetails.email.isNotEmpty) {
      return applicantDetails.email.split('@')[0];
    }

    return 'Applicant';
  }

  bool _hasExpectedSalary(Map<String, dynamic>? info) {
    if (info == null) return false;
    final salary = info['expectedSalary'];
    return salary != null;
  }

  String _getExpectedSalaryText(dynamic expectedSalary) {
    if (expectedSalary == null) return 'Expected: N/A';
    if (expectedSalary is Map) {
      final amount = expectedSalary['amount'];
      final currency = expectedSalary['currency'] ?? '\$';
      if (amount != null) {
        return 'Expected: ${NumberFormat.currency(symbol: currency, decimalDigits: 0).format(amount)}';
      }
    }
    return 'Expected: $expectedSalary';
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending': color = AppColors.pending; break;
      case 'accepted': color = AppColors.success; break;
      case 'rejected': color = AppColors.rejected; break;
      case 'shortlisted': color = AppColors.shortlisted; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}