import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/job_model.dart';
import '../providers/jobs_provider.dart';
import './screening_questions.dart';

class EditJobScreen extends ConsumerStatefulWidget {
  final String jobId; // Changed from JobModel to String ID
  const EditJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends ConsumerState<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _salaryMinController;
  late TextEditingController _salaryMaxController;

  String _jobType = 'full-time';
  List<Map<String, dynamic>> _screeningQuestions = [];
  bool _isInitialized = false; // To prevent controllers from resetting on every build

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _salaryMinController = TextEditingController();
    _salaryMaxController = TextEditingController();
  }

  // Initialize data once the provider loads
  void _initializeData(JobModel job) {
    if (_isInitialized) return;
    _titleController.text = job.title;
    _salaryMinController.text = job.salary?.min?.toString() ?? '';
    _salaryMaxController.text = job.salary?.max?.toString() ?? '';
    _jobType = job.jobType ?? 'full-time';
    // Convert backend list to dynamic map for the builder
    // FIX: Convert the Model objects into the Maps the UI builder expects
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
      'screeningQuestions': _screeningQuestions, // Now includes the new questions
    };

    final success = await ref
        .read(jobUpdateControllerProvider.notifier)
        .updateJob(widget.jobId, updates);

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job updated successfully! 🎉'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the job details
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final updateState = ref.watch(jobUpdateControllerProvider);

    return jobAsync.when(
      data: (job) {
        _initializeData(job); // Populate controllers

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Job Posting'),
            actions: [
              if (updateState.isLoading)
                const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
              else
                IconButton(onPressed: _submitUpdate, icon: const Icon(Icons.check, color: Colors.green, size: 28))
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildFieldLabel('Job Title'),
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration('e.g. Senior Flutter Developer'),
                  validator: (v) => v!.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Employment Type'),
                DropdownButtonFormField<String>(
                  value: _jobType,
                  items: ['full-time', 'part-time', 'contract', 'internship']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => _jobType = val!),
                  decoration: _inputDecoration(''),
                ),
                const SizedBox(height: 20),
                _buildFieldLabel('Salary Range (Monthly)'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMinController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Min'),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('to')),
                    Expanded(
                      child: TextFormField(
                        controller: _salaryMaxController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Max'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ScreeningQuestionsBuilder(
                  initialQuestions: _screeningQuestions,
                  onChanged: (newList) {
                    _screeningQuestions = newList;
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }



  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _buildFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
  );
}