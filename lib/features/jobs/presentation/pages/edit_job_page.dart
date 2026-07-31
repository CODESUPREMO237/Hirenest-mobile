import 'package:flutter/material.dart';
import '../../../../core/widgets/error_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/job_model.dart';
import '../providers/jobs_provider.dart';
import './screening_questions.dart';

class EditJobScreen extends ConsumerStatefulWidget {
  final String jobId;
  const EditJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends ConsumerState<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _salaryMinController;
  late TextEditingController _salaryMaxController;

  String _jobType = 'full-time';
  List<Map<String, dynamic>> _screeningQuestions = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _salaryMinController = TextEditingController();
    _salaryMaxController = TextEditingController();
  }

  void _initializeData(JobModel job) {
    if (_isInitialized) return;
    _titleController.text = job.title;
    _salaryMinController.text = job.salary?.min?.toString() ?? '';
    _salaryMaxController.text = job.salary?.max?.toString() ?? '';
    _jobType = job.jobType;
    _screeningQuestions = (job.screeningQuestions ?? []).map((q) {
      return {
        'question': q.question,
        'type': q.type,
        'required': q.required,
        'options': List<String>.from(q.options ?? []),
      };
    }).toList();
    _isInitialized = true;
  }

  void _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final updates = {
      'title': _titleController.text.trim(),
      'jobType': _jobType,
      'salary': {
        'min': int.tryParse(_salaryMinController.text),
        'max': int.tryParse(_salaryMaxController.text),
        'currency': 'XAF',
      },
      'screeningQuestions': _screeningQuestions,
    };

    final success = await ref
        .read(jobUpdateControllerProvider.notifier)
        .updateJob(widget.jobId, updates);

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job updated successfully! 🎉'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final updateState = ref.watch(jobUpdateControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit Job Posting'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        actions: [
          if (updateState.isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md), 
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2)
              )
            )
          else
            IconButton(
              onPressed: _submitUpdate,
              icon: const Icon(Icons.check, color: AppColors.success, size: 28)
            )
        ],
      ),
      body: jobAsync.when(
        data: (job) {
          _initializeData(job);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _buildFieldLabel('Job Title'),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration('e.g. Senior Flutter Developer'),
                  validator: (v) => v!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                
                _buildFieldLabel('Employment Type'),
                DropdownButtonFormField<String>(
                  initialValue: _jobType,
                  items: ['full-time', 'part-time', 'contract', 'internship']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => _jobType = val!),
                  decoration: _inputDecoration('Select Job Type'),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                _buildFieldLabel('Salary Range (Monthly in XAF)'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMinController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Min'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('to', style: TextStyle(color: AppColors.textSecondaryLight)),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMaxController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Max'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                
                ScreeningQuestionsBuilder(
                  initialQuestions: _screeningQuestions,
                  onChanged: (newList) {
                    _screeningQuestions = newList;
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => CustomErrorWidget(error: e),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
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
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
  );

  Widget _buildFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
        fontSize: 14,
      )
    ),
  );
}