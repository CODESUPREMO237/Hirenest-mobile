import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/job_model.dart';

class JobDetailsSection extends StatelessWidget {
  final JobModel job;

  const JobDetailsSection({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Description',
            Text(
              job.description,
              style: const TextStyle(
                height: 1.6, 
                color: AppColors.textSecondaryLight,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _buildSection(
            'Requirements',
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppSpacing.roundedLg,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: job.requirements.skills.map((skill) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            skill.name,
                            style: const TextStyle(fontSize: 15, color: AppColors.textPrimaryLight),
                          ),
                        ),
                        if (skill.required)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: AppSpacing.roundedSm,
                            ),
                            child: const Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 11, 
                                color: AppColors.error, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          if (job.benefits.isNotEmpty)
            _buildSection(
              'Benefits',
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: job.benefits.map((benefit) {
                  return Chip(
                    label: Text(benefit, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                    backgroundColor: AppColors.surfaceLight,
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        content,
      ],
    );
  }
}