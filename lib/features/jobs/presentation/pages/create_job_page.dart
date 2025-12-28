import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/jobs_provider.dart';
import '../../data/repositories/jobs_repository.dart';

class CreateJobPage extends ConsumerStatefulWidget {
  const CreateJobPage({super.key});

  @override
  ConsumerState<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends ConsumerState<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();

  String _jobType = 'full-time';
  String _category = 'Technology';
  String _experienceLevel = 'mid';
  String _locationType = 'onsite';
  bool _showSalary = true;
  bool _isSubmitting = false;

  final List<String> _selectedBenefits = [];
  final List<Map<String, dynamic>> _skills = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  void _addSkill() {
    showDialog(
      context: context,
      builder: (context) {
        String skillName = '';
        bool isRequired = true;
        String level = 'intermediate';

        return AlertDialog(
          title: const Text('Add Skill'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Skill Name'),
                    onChanged: (value) => skillName = value,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: level,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: const [
                      DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                      DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                      DropdownMenuItem(value: 'expert', child: Text('Expert')),
                    ],
                    onChanged: (value) => setState(() => level = value!),
                  ),
                  CheckboxListTile(
                    title: const Text('Required'),
                    value: isRequired,
                    onChanged: (value) => setState(() => isRequired = value!),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (skillName.isNotEmpty) {
                  setState(() {
                    _skills.add({
                      'name': skillName,
                      'level': level,
                      'required': isRequired,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addBenefit() {
    showDialog(
      context: context,
      builder: (context) {
        String benefit = '';

        return AlertDialog(
          title: const Text('Add Benefit'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Benefit',
              hintText: 'e.g., Health Insurance',
            ),
            onChanged: (value) => benefit = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (benefit.isNotEmpty) {
                  setState(() => _selectedBenefits.add(benefit));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one skill')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(jobsRepositoryProvider);

      await repository.createJob(
        title: _titleController.text,
        description: _descriptionController.text,
        jobType: _jobType,
        category: _category,
        experienceLevel: _experienceLevel,
        location: {
          'type': _locationType,
          'address': {
            'city': _cityController.text,
            'country': 'Cameroon',
          },
          'coordinates': {
            'type': 'Point',
            'coordinates': [0.0, 0.0], // Default coords to satisfy MongoDB index
          },
        },
        salary: {
          'min': double.parse(_minSalaryController.text),
          'max': double.parse(_maxSalaryController.text),
          'currency': 'XAF',
          'period': 'monthly',
          'showSalary': _showSalary,
        },
        skills: _skills,
        benefits: _selectedBenefits,
      );

      if (mounted) {
        // Refresh jobs list
        ref.invalidate(myJobsProvider);

        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post job: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Job Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title *',
                  hintText: 'e.g., Senior Full-Stack Developer',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter job title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Job Type
              DropdownButtonFormField<String>(
                value: _jobType,
                decoration: const InputDecoration(labelText: 'Job Type *'),
                items: const [
                  DropdownMenuItem(value: 'full-time', child: Text('Full-time')),
                  DropdownMenuItem(value: 'part-time', child: Text('Part-time')),
                  DropdownMenuItem(value: 'contract', child: Text('Contract')),
                  DropdownMenuItem(value: 'internship', child: Text('Internship')),
                  DropdownMenuItem(value: 'freelance', child: Text('Freelance')),
                ],
                onChanged: (value) => setState(() => _jobType = value!),
              ),

              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: const [
                  DropdownMenuItem(value: 'Technology', child: Text('Technology')),
                  DropdownMenuItem(value: 'Marketing', child: Text('Marketing')),
                  DropdownMenuItem(value: 'Sales', child: Text('Sales')),
                  DropdownMenuItem(value: 'Design', child: Text('Design')),
                  DropdownMenuItem(value: 'Finance', child: Text('Finance')),
                  DropdownMenuItem(value: 'Healthcare', child: Text('Healthcare')),
                  DropdownMenuItem(value: 'Education', child: Text('Education')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _category = value!),
              ),

              const SizedBox(height: 16),

              // Experience Level
              DropdownButtonFormField<String>(
                value: _experienceLevel,
                decoration: const InputDecoration(labelText: 'Experience Level *'),
                items: const [
                  DropdownMenuItem(value: 'entry', child: Text('Entry Level')),
                  DropdownMenuItem(value: 'mid', child: Text('Mid Level')),
                  DropdownMenuItem(value: 'senior', child: Text('Senior')),
                  DropdownMenuItem(value: 'executive', child: Text('Executive')),
                ],
                onChanged: (value) => setState(() => _experienceLevel = value!),
              ),

              const SizedBox(height: 24),

              // Location Type
              Text(
                'Work Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'onsite', label: Text('On-site')),
                  ButtonSegment(value: 'remote', label: Text('Remote')),
                  ButtonSegment(value: 'hybrid', label: Text('Hybrid')),
                ],
                selected: {_locationType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _locationType = newSelection.first);
                },
              ),

              const SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  hintText: 'Douala',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Salary Range
              Text(
                'Salary Range (XAF/month)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSalaryController,
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        prefixText: 'XAF ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSalaryController,
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        prefixText: 'XAF ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                title: const Text('Show salary to applicants'),
                value: _showSalary,
                onChanged: (value) => setState(() => _showSalary = value!),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Job Description *',
                  hintText: 'Describe the role, responsibilities, and what you\'re looking for...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter job description';
                  }
                  if (value.length < 200) {
                    return 'Description should be at least 200 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Skills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Required Skills *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addSkill,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Skill'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_skills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('No skills added yet'),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((skill) {
                    return Chip(
                      label: Text('${skill['name']} (${skill['level']})'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _skills.remove(skill));
                      },
                      backgroundColor: skill['required']
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // Benefits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Benefits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addBenefit,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Benefit'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedBenefits.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('No benefits added yet'),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedBenefits.map((benefit) {
                    return Chip(
                      label: Text(benefit),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() => _selectedBenefits.remove(benefit));
                      },
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitJob,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Post Job'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}