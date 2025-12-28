import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/repositories/jobs_repository.dart';
import '../providers/jobs_provider.dart';
import '../widgets/apply_form.dart';

class ApplyJobPage extends ConsumerStatefulWidget {
  final String jobId;

  const ApplyJobPage({super.key, required this.jobId});

  @override
  ConsumerState<ApplyJobPage> createState() => _ApplyJobPageState();
}

class _ApplyJobPageState extends ConsumerState<ApplyJobPage> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleSubmit(
      XFile resume,
      String coverLetter,
      List<Map<String, dynamic>> screeningAnswers,
      ) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    AppLogger.info('Starting job application for Job ID: ${widget.jobId}');

    try {
      await ref.read(jobsRepositoryProvider).applyToJob(
        jobId: widget.jobId,
        coverLetter: coverLetter,
        resumeFile: resume,
        screeningAnswers: screeningAnswers,
      );

      // Refresh user data after successful application
      ref.invalidate(currentUserProvider);
      ref.invalidate(profileProvider);

      AppLogger.info('Application successful for Job ID: ${widget.jobId}');

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Applied successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to apply: ${widget.jobId}',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(currentUserProvider);
    final jobDetail = ref.watch(jobDetailProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Job'),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please login to apply'));
          }

          return jobDetail.when(
            data: (job) {
              if (_errorMessage != null) {
                return CustomErrorWidget(
                  message: _errorMessage!,
                  onRetry: () => setState(() => _errorMessage = null),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTipsCard(),
                    const SizedBox(height: 24),
                    ApplyForm(
                      jobId: widget.jobId,
                      user: user,
                      screeningQuestions: job.screeningQuestions ?? [],
                      onSubmit: _handleSubmit,
                      isSubmitting: _isSubmitting,
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => CustomErrorWidget(
              message: 'Error loading job requirements',
              onRetry: () => ref.invalidate(jobDetailProvider(widget.jobId)),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => CustomErrorWidget(
          message: 'Could not load profile info',
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Application Tip',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your profile details (Education, Experience, and Skills) will be automatically attached to this application.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }
}