import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/job_model.dart';

class ApplyForm extends StatefulWidget {
  final String jobId;
  final UserModel user;
  final Function(XFile resume, String coverLetter, List<Map<String, dynamic>> screeningAnswers) onSubmit;
  final bool isSubmitting;
  final List<ScreeningQuestionModel> screeningQuestions;

  const ApplyForm({
    super.key,
    required this.jobId,
    required this.user,
    required this.onSubmit,
    required this.isSubmitting,
    this.screeningQuestions = const [],
  });

  @override
  State<ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends State<ApplyForm> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  XFile? _selectedResume;
  final Map<String, dynamic> _answers = {};

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedResume = XFile(result.files.single.path!);
      });
    }
  }

  void _handleLocalSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedResume == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a resume'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final formattedAnswers = _answers.entries.map((e) => {
      'question': e.key,
      'answer': e.value,
    }).toList();

    widget.onSubmit(
      _selectedResume!,
      _coverLetterController.text,
      formattedAnswers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.user.jobSeekerProfile;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Your Profile Details'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                _buildProfileRow(
                  Icons.school_outlined,
                  'Education',
                  '${profile?.education?.length ?? 0} records',
                ),
                const Divider(height: AppSpacing.lg),
                _buildProfileRow(
                  Icons.work_outline,
                  'Experience',
                  '${profile?.experience?.length ?? 0} records',
                ),
                const Divider(height: AppSpacing.lg),
                _buildProfileRow(
                  Icons.psychology_outlined,
                  'Skills',
                  '${profile?.skills?.length ?? 0} skills identified',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _buildSectionHeader('Cover Letter'),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _coverLetterController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Explain why you are the best fit...',
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
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _buildSectionHeader('Resume (Required)'),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: widget.isSubmitting ? null : _pickResume,
            borderRadius: AppSpacing.roundedLg,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: _selectedResume == null ? AppColors.surfaceLight : AppColors.primary.withValues(alpha: 0.05),
                border: Border.all(
                  color: _selectedResume == null ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                  width: _selectedResume == null ? 1 : 2,
                ),
                borderRadius: AppSpacing.roundedLg,
              ),
              child: _selectedResume == null
                  ? Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.upload_file, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Tap to upload PDF/DOCX', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondaryLight)),
                ],
              )
                  : Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedResume!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                        const Text('Resume attached', style: TextStyle(fontSize: 12, color: AppColors.success)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.isSubmitting ? null : _pickResume,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          if (widget.screeningQuestions.isNotEmpty) ...[
            _buildSectionHeader('Employer Questions'),
            const SizedBox(height: AppSpacing.md),
            ...widget.screeningQuestions.map((q) => _buildQuestionInput(q)),
            const SizedBox(height: AppSpacing.xl),
          ],

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.isSubmitting ? null : _handleLocalSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                elevation: 0,
              ),
              child: widget.isSubmitting
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)
                    )
                  : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textSecondaryLight)),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(ScreeningQuestionModel q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: q.question,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimaryLight),
              children: [
                if (q.required)
                  const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (q.type == 'text')
            TextFormField(
              decoration: _inputDecoration("Your answer"),
              validator: (v) => q.required && (v == null || v.trim().isEmpty)
                  ? "This field is required"
                  : null,
              onChanged: (val) => _answers[q.question] = val,
            )
          else if (q.type == 'yes_no')
            Row(
              children: [
                _answerChip(q.question, "Yes"),
                const SizedBox(width: AppSpacing.sm),
                _answerChip(q.question, "No"),
              ],
            )
          else if (q.type == 'multiple_choice' && q.options != null)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: q.options!.map((opt) => _answerChip(q.question, opt)).toList(),
              ),
        ],
      ),
    );
  }

  Widget _answerChip(String question, String value) {
    bool isSelected = _answers[question] == value;
    return ChoiceChip(
      label: Text(value),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundColor: AppColors.surfaceLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.borderLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
      onSelected: (selected) {
        setState(() => _answers[question] = value);
      },
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
    errorBorder: OutlineInputBorder(
      borderRadius: AppSpacing.roundedMd,
      borderSide: const BorderSide(color: AppColors.error),
    ),
  );
}