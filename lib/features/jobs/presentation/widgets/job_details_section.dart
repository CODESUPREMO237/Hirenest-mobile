// lib/features/jobs/presentation/widgets/job_details_section.dart
import 'package:flutter/material.dart';
import '../../data/models/job_model.dart';

class JobDetailsSection extends StatelessWidget {
  final JobModel job;

  const JobDetailsSection({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Description',
            Text(
              job.description,
              style: TextStyle(height: 1.5, color: Colors.grey[800]),
            ),
          ),
          const SizedBox(height: 24),

          // Requirements Section
          _buildSection(
            'Requirements',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: job.requirements.skills.map((skill) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          skill.name,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      if (skill.required)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Benefits Section
          if (job.benefits.isNotEmpty)
            _buildSection(
              'Benefits',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.benefits.map((benefit) {
                  return Chip(
                    label: Text(benefit, style: const TextStyle(fontSize: 13)),
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(color: Colors.grey.shade300),
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
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }
}