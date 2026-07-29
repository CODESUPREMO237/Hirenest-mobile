// lib/features/Application/presentation/widgets/application_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/application_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
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
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildStatusBadge(application.status, textTheme),
                  ],
                ),

                // ✅ CONDITIONAL DISPLAY: Show different info for employer vs job seeker
                if (isEmployerView) ...[
                  // EMPLOYER VIEW: Show applicant name
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Theme.of(context).primaryColor),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _getApplicantName(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // JOB SEEKER VIEW: Show company name
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
                    child: Text(
                      companyName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                Divider(height: AppSpacing.xl, color: AppColors.borderLight),

                // LOCATION AND DATE ROW
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMutedLight),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      city,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMutedLight),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      application.appliedAt != null
                          ? DateFormat('MMM dd, yyyy').format(application.appliedAt!)
                          : 'N/A',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),

                // SALARY SECTION
                if (_hasExpectedSalary(application.additionalInfo)) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 16, color: AppColors.success),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _getExpectedSalaryText(application.additionalInfo?['expectedSalary']),
                        style: textTheme.bodySmall?.copyWith(
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
      ),
    );
  }

  // --- Helpers ---

  String _getApplicantName() {
    final applicantDetails = application.applicantDetails;

    if (applicantDetails == null) {
      return 'Applicant';
    }

    final profile = applicantDetails.profile;
    if (profile != null) {
      final firstName = profile.firstName ?? '';
      final lastName = profile.lastName ?? '';
      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) {
        return fullName;
      }

      if (profile.displayName != null && profile.displayName!.isNotEmpty) {
        return profile.displayName!;
      }
    }

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

  Widget _buildStatusBadge(String status, TextTheme textTheme) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pending': color = AppColors.warning; break;
      case 'accepted': color = AppColors.success; break;
      case 'rejected': color = AppColors.error; break;
      case 'shortlisted': color = AppColors.primary; break;
      default: color = AppColors.textMutedLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Text(
        status.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}