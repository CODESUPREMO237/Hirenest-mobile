import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
          title: Text('Add Skill', style: Theme.of(context).textTheme.titleLarge),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Skill Name',
                      border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                    onChanged: (value) => skillName = value,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: InputDecoration(
                      labelText: 'Level',
                      border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                      DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                      DropdownMenuItem(value: 'expert', child: Text('Expert')),
                    ],
                    onChanged: (value) => setState(() => level = value!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    title: const Text('Required'),
                    value: isRequired,
                    onChanged: (value) => setState(() => isRequired = value!),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
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
                if (skillName.trim().isNotEmpty) {
                  setState(() {
                    _skills.add({
                      'name': skillName.trim(),
                      'level': level,
                      'required': isRequired,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
              ),
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
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
          title: Text('Add Benefit', style: Theme.of(context).textTheme.titleLarge),
          content: TextField(
            decoration: InputDecoration(
              labelText: 'Benefit',
              hintText: 'e.g., Health Insurance',
              border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            onChanged: (value) => benefit = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (benefit.trim().isNotEmpty) {
                  setState(() => _selectedBenefits.add(benefit.trim()));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one skill'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final minSalary = double.tryParse(_minSalaryController.text.trim().replaceAll(RegExp(r'[,\s]'), ''));
    final maxSalary = double.tryParse(_maxSalaryController.text.trim().replaceAll(RegExp(r'[,\s]'), ''));

    if (minSalary == null || maxSalary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid salary amounts'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (minSalary >= maxSalary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum salary must be greater than minimum salary'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (minSalary < 0 || maxSalary < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salary amounts cannot be negative'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(jobsRepositoryProvider);
      await repository.createJob(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        jobType: _jobType,
        category: _category,
        experienceLevel: _experienceLevel,
        location: {
          'type': _locationType,
          'address': {
            'city': _cityController.text.trim(),
            'country': 'Cameroon',
          },
          'coordinates': {
            'type': 'Point',
            'coordinates': [0.0, 0.0],
          },
        },
        salary: {
          'min': minSalary,
          'max': maxSalary,
          'currency': 'XAF',
          'period': 'monthly',
          'showSalary': _showSalary,
        },
        skills: _skills,
        benefits: _selectedBenefits,
      );

      if (mounted) {
        ref.invalidate(myJobsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post job: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: AppSpacing.roundedMd,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedMd,
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.roundedMd,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Post a Job'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Job Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Job Title *', hint: 'e.g., Senior Full-Stack Developer'),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter job title';
                  if (value.trim().length < 3) return 'Job title must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                initialValue: _jobType,
                decoration: _inputDecoration('Job Type *'),
                items: const [
                  DropdownMenuItem(value: 'full-time', child: Text('Full-time')),
                  DropdownMenuItem(value: 'part-time', child: Text('Part-time')),
                  DropdownMenuItem(value: 'contract', child: Text('Contract')),
                  DropdownMenuItem(value: 'internship', child: Text('Internship')),
                  DropdownMenuItem(value: 'freelance', child: Text('Freelance')),
                ],
                onChanged: (value) => setState(() => _jobType = value!),
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _inputDecoration('Category *'),
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
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                initialValue: _experienceLevel,
                decoration: _inputDecoration('Experience Level *'),
                items: const [
                  DropdownMenuItem(value: 'entry', child: Text('Entry Level')),
                  DropdownMenuItem(value: 'mid', child: Text('Mid Level')),
                  DropdownMenuItem(value: 'senior', child: Text('Senior')),
                  DropdownMenuItem(value: 'executive', child: Text('Executive')),
                ],
                onChanged: (value) => setState(() => _experienceLevel = value!),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                'Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
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
                style: SegmentedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                  selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  selectedForegroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _cityController,
                decoration: _inputDecoration('City *', hint: 'e.g., Douala'),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter city';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                'Compensation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSalaryController,
                      decoration: _inputDecoration('Min Salary', prefixText: 'XAF '),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final salary = double.tryParse(value.trim().replaceAll(RegExp(r'[,\s]'), ''));
                        if (salary == null || salary <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSalaryController,
                      decoration: _inputDecoration('Max Salary', prefixText: 'XAF '),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final salary = double.tryParse(value.trim().replaceAll(RegExp(r'[,\s]'), ''));
                        if (salary == null || salary <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                title: Text('Show salary to applicants', style: Theme.of(context).textTheme.bodyMedium),
                value: _showSalary,
                onChanged: (value) => setState(() => _showSalary = value!),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xl),

              TextFormField(
                controller: _descriptionController,
                maxLines: 8,
                decoration: _inputDecoration('Job Description *', hint: 'Describe the role...').copyWith(alignLabelWithHint: true),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter job description';
                  if (value.trim().length < 200) return 'Description should be at least 200 characters (${value.trim().length}/200)';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Required Skills *',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addSkill,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text('Add Skill', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              if (_skills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: const Center(
                    child: Text('No skills added yet', style: TextStyle(color: AppColors.textMutedLight)),
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _skills.map((skill) {
                    return Chip(
                      label: Text('${skill['name']} (${skill['level']})'),
                      labelStyle: TextStyle(
                        color: skill['required'] ? AppColors.primaryDark : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                      deleteIcon: Icon(Icons.close, size: 18, color: skill['required'] ? AppColors.primaryDark : AppColors.textSecondaryLight),
                      onDeleted: () => setState(() => _skills.remove(skill)),
                      backgroundColor: skill['required'] ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
                      side: BorderSide(color: skill['required'] ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                    );
                  }).toList(),
                ),

              const SizedBox(height: AppSpacing.xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Benefits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addBenefit,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text('Add Benefit', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              if (_selectedBenefits.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: const Center(
                    child: Text('No benefits added yet', style: TextStyle(color: AppColors.textMutedLight)),
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _selectedBenefits.map((benefit) {
                    return Chip(
                      label: Text(benefit, style: const TextStyle(color: AppColors.textSecondaryLight)),
                      deleteIcon: const Icon(Icons.close, size: 18, color: AppColors.textSecondaryLight),
                      onDeleted: () => setState(() => _selectedBenefits.remove(benefit)),
                      backgroundColor: AppColors.surfaceLight,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                    );
                  }).toList(),
                ),

              const SizedBox(height: AppSpacing.xxl),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                      )
                    : const Text('Post Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}