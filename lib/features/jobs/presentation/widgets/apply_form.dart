import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/job_model.dart';

class ApplyForm extends StatefulWidget {
  final String jobId;
  final UserModel user;
  final Function(XFile resume, String coverLetter, List<Map<String, dynamic>> screeningAnswers) onSubmit;
  final bool isSubmitting;
  final List<ScreeningQuestionModel> screeningQuestions; // ✅ Changed type

  const ApplyForm({
    super.key,
    required this.jobId,
    required this.user,
    required this.onSubmit,
    required this.isSubmitting,
    this.screeningQuestions = const [], // ✅ Default empty list
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
        const SnackBar(content: Text('Please upload a resume')),
      );
      return;
    }

    // Convert answers map to list format for backend
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
          // --- 1. PROFILE PREVIEW SECTION ---
          _buildSectionHeader('Your Profile Details'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              children: [
                _buildProfileRow(
                  Icons.school,
                  'Education',
                  '${profile?.education?.length ?? 0} records',
                ),
                const Divider(),
                _buildProfileRow(
                  Icons.work,
                  'Experience',
                  '${profile?.experience?.length ?? 0} records',
                ),
                const Divider(),
                _buildProfileRow(
                  Icons.psychology,
                  'Skills',
                  '${profile?.skills?.length ?? 0} skills identified',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- 2. COVER LETTER ---
          _buildSectionHeader('Cover Letter'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _coverLetterController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Explain why you are the best fit...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- 3. RESUME UPLOAD ---
          _buildSectionHeader('Resume (Required)'),
          const SizedBox(height: 8),
          InkWell(
            onTap: widget.isSubmitting ? null : _pickResume,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedResume == null
                  ? const Column(
                children: [
                  Icon(Icons.upload_file, size: 40, color: Colors.blue),
                  SizedBox(height: 8),
                  Text('Tap to upload PDF/DOCX'),
                ],
              )
                  : Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_selectedResume!.name)),
                  const Text(
                    'Change',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // --- 4. SCREENING QUESTIONS ---
          if (widget.screeningQuestions.isNotEmpty) ...[
            _buildSectionHeader('Employer Questions'),
            const SizedBox(height: 16),
            ...widget.screeningQuestions.map((q) => _buildQuestionInput(q)),
            const SizedBox(height: 24),
          ],

          // --- 5. SUBMIT BUTTON ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: widget.isSubmitting ? null : _handleLocalSubmit,
              child: widget.isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Application'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(ScreeningQuestionModel q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${q.question}${q.required ? ' *' : ''}",
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          const SizedBox(height: 8),

          if (q.type == 'text')
            TextFormField(
              decoration: _inputDecoration("Your answer"),
              validator: (v) => q.required && (v == null || v.isEmpty)
                  ? "This field is required"
                  : null,
              onChanged: (val) => _answers[q.question] = val,
            )
          else if (q.type == 'yes_no')
            Row(
              children: [
                _answerChip(q.question, "Yes"),
                const SizedBox(width: 10),
                _answerChip(q.question, "No"),
              ],
            )
          else if (q.type == 'multiple_choice' && q.options != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
      onSelected: (selected) {
        setState(() => _answers[question] = value);
      },
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}