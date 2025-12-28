// Job Filter Sheet
// lib/features/jobs/presentation/widgets/job_filter_sheet.dart
import 'package:flutter/material.dart';
import '../providers/jobs_provider.dart';

class JobFilterSheet extends StatefulWidget {
  final Function(JobFilters) onApply;
  const JobFilterSheet({super.key, required this.onApply});

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  String? _selectedCategory;
  String? _selectedJobType;
  String? _selectedExperienceLevel;
  bool? _remoteOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Jobs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          // Category
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Technology', 'Marketing', 'Sales', 'Design', 'Other']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),

          const SizedBox(height: 16),

          // Job Type
          DropdownButtonFormField<String>(
            value: _selectedJobType,
            decoration: const InputDecoration(labelText: 'Job Type'),
            items: ['full-time', 'part-time', 'contract', 'internship']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (value) => setState(() => _selectedJobType = value),
          ),

          const SizedBox(height: 16),

          // Remote Only
          CheckboxListTile(
            title: const Text('Remote Only'),
            value: _remoteOnly ?? false,
            onChanged: (value) => setState(() => _remoteOnly = value),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedJobType = null;
                      _remoteOnly = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(JobFilters(
                      category: _selectedCategory,
                      jobType: _selectedJobType,
                      remote: _remoteOnly,
                    ));
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}