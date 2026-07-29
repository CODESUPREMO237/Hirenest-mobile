import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  List<SkillModel> _skills = [];
  List<EducationModel> _education = [];
  List<ExperienceModel> _experience = [];
  List<String> _selectedJobTypes = [];
  int? _minSalary;
  int? _maxSalary;
  String _currency = 'USD';
  bool _willingToRelocate = false;
  DateTime? _availableFrom;

  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _populateControllers(ProfileModel profile) {
    if (!_initialized) {
      _firstNameController.text = profile.profile?.firstName ?? '';
      _lastNameController.text = profile.profile?.lastName ?? '';
      _phoneController.text = profile.profile?.phone ?? '';
      _bioController.text = profile.profile?.bio ?? '';
      _cityController.text = profile.profile?.location?.city ?? '';
      _countryController.text = profile.profile?.location?.country ?? '';

      if (profile.role.toLowerCase() == 'jobseeker' && profile.jobSeekerProfile != null) {
        _skills = List.from(profile.jobSeekerProfile!.skills);
        _education = List.from(profile.jobSeekerProfile!.education);
        _experience = List.from(profile.jobSeekerProfile!.experience);
        _selectedJobTypes = List.from(profile.jobSeekerProfile!.preferences?.jobTypes ?? []);
        _minSalary = profile.jobSeekerProfile!.preferences?.expectedSalary?.min;
        _maxSalary = profile.jobSeekerProfile!.preferences?.expectedSalary?.max;
        _currency = profile.jobSeekerProfile!.preferences?.expectedSalary?.currency ?? 'USD';
        _willingToRelocate = profile.jobSeekerProfile!.preferences?.willingToRelocate ?? false;
        _availableFrom = profile.jobSeekerProfile!.preferences?.availableFrom;
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (profile) {
          _populateControllers(profile);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _buildProfilePictureSection(profile),
                const SizedBox(height: AppSpacing.xxl),
                _buildBasicInfoSection(),
                const SizedBox(height: AppSpacing.xl),
                if (profile.role.toLowerCase() == 'jobseeker') ...[
                  _buildCVSection(profile),
                  const SizedBox(height: AppSpacing.xl),
                  _buildSkillsSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildEducationSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildExperienceSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildPreferencesSection(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePictureSection(ProfileModel profile) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              shape: BoxShape.circle,
              image: (profile.profile?.avatar != null && profile.profile!.avatar!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(profile.profile!.avatar!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (profile.profile?.avatar == null || profile.profile!.avatar!.isEmpty)
                ? const Icon(Icons.person, size: 50, color: AppColors.textMutedLight)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: InkWell(
              onTap: _isLoading ? null : _handleAvatarUpload,
              borderRadius: AppSpacing.roundedFull,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceLight, width: 2),
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMutedLight),
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
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Info',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _firstNameController,
          decoration: _inputDecoration('First Name'),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _lastNameController,
          decoration: _inputDecoration('Last Name'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _phoneController,
          decoration: _inputDecoration('Phone'),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _bioController,
          decoration: _inputDecoration('Bio').copyWith(alignLabelWithHint: true),
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: _inputDecoration('City'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _countryController,
                decoration: _inputDecoration('Country'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCVSection(ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.borderLight),
        const SizedBox(height: AppSpacing.sm),
        Text('Resume / CV',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                )),
        const SizedBox(height: AppSpacing.md),
        if (profile.jobSeekerProfile?.resume != null && profile.jobSeekerProfile!.resume!['url'] != null)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: ListTile(
              leading: const Icon(Icons.description, color: AppColors.primary),
              title: Text(
                profile.jobSeekerProfile!.resume!['filename'] ?? 'Resume.pdf',
                style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: AppColors.textSecondaryLight),
                    onPressed: () async {
                      final url = profile.jobSeekerProfile!.resume!['url'];
                      if (url != null) await launchUrl(Uri.parse(url));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: _isLoading ? null : _handleDeleteCV,
                  ),
                ],
              ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleCVUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Resume'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.borderLight),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Skills',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    )),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () => _showAddSkillDialog(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_skills.isEmpty)
          const Text('No skills added yet', style: TextStyle(color: AppColors.textMutedLight))
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _skills.map((skill) => Chip(
                  label: Text('${skill.name} (${skill.level})'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _skills.remove(skill)),
                  backgroundColor: AppColors.surfaceLight,
                  side: const BorderSide(color: AppColors.borderLight),
                  labelStyle: const TextStyle(color: AppColors.textPrimaryLight),
                )).toList(),
          ),
      ],
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.borderLight),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Education',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    )),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () => _showAddEducationDialog(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_education.isEmpty)
          const Text('No education added yet', style: TextStyle(color: AppColors.textMutedLight))
        else
          ..._education.map((edu) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ListTile(
                  title: Text(edu.degree, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${edu.institution}\n${edu.fieldOfStudy}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => setState(() => _education.remove(edu)),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.borderLight),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Experience',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    )),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () => _showAddExperienceDialog(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_experience.isEmpty)
          const Text('No experience added yet', style: TextStyle(color: AppColors.textMutedLight))
        else
          ..._experience.map((exp) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: ListTile(
                  title: Text(exp.position, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${exp.company}\n${exp.location ?? ""}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => setState(() => _experience.remove(exp)),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.borderLight),
        const SizedBox(height: AppSpacing.sm),
        Text('Job Preferences',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                )),
        const SizedBox(height: AppSpacing.lg),

        Text('Preferred Job Types', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: ['full-time', 'part-time', 'contract', 'internship', 'freelance'].map((type) {
            return FilterChip(
              label: Text(type),
              selected: _selectedJobTypes.contains(type),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide(
                color: _selectedJobTypes.contains(type) ? AppColors.primary : AppColors.borderLight,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedJobTypes.add(type);
                  } else {
                    _selectedJobTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text('Expected Salary', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: _inputDecoration('Min'),
                keyboardType: TextInputType.number,
                initialValue: _minSalary?.toString(),
                onChanged: (v) => _minSalary = int.tryParse(v),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                decoration: _inputDecoration('Max'),
                keyboardType: TextInputType.number,
                initialValue: _maxSalary?.toString(),
                onChanged: (v) => _maxSalary = int.tryParse(v),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currency,
                  items: ['USD', 'EUR', 'GBP', 'XAF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _currency = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: SwitchListTile(
            title: const Text('Willing to Relocate', style: TextStyle(fontWeight: FontWeight.w500)),
            value: _willingToRelocate,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _willingToRelocate = v),
          ),
        ),
      ],
    );
  }

  void _showAddSkillDialog() {
    final nameController = TextEditingController();
    String selectedLevel = 'beginner';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: const Text('Add Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: _inputDecoration('Skill Name'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: selectedLevel,
                decoration: _inputDecoration('Proficiency Level'),
                items: ['beginner', 'intermediate', 'advanced', 'expert']
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (v) => setState(() => selectedLevel = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  this.setState(() {
                    _skills.add(SkillModel(name: nameController.text, level: selectedLevel));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEducationDialog() {
    final institutionController = TextEditingController();
    final degreeController = TextEditingController();
    final fieldController = TextEditingController();
    final descController = TextEditingController();
    bool isCurrent = false;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: const Text('Add Education'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: institutionController, decoration: _inputDecoration('Institution')),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: degreeController, decoration: _inputDecoration('Degree')),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: fieldController, decoration: _inputDecoration('Field of Study')),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: descController, decoration: _inputDecoration('Description'), maxLines: 2),
                const SizedBox(height: AppSpacing.sm),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(startDate == null ? 'Select Start Date' : 'Start: ${startDate!.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: () => _selectDate(context, startDate, (date) => setDialogState(() => startDate = date)),
                ),

                if (!isCurrent)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(endDate == null ? 'Select End Date' : 'End: ${endDate!.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                    onTap: () => _selectDate(context, endDate, (date) => setDialogState(() => endDate = date)),
                  ),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Currently Studying'),
                  value: isCurrent,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setDialogState(() => isCurrent = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
              ),
              onPressed: () {
                if (institutionController.text.isNotEmpty) {
                  if (startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start Date is required')));
                    return;
                  }
                  setState(() {
                    _education.add(EducationModel(
                      institution: institutionController.text,
                      degree: degreeController.text,
                      fieldOfStudy: fieldController.text,
                      description: descController.text,
                      current: isCurrent,
                      startDate: startDate,
                      endDate: endDate,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExperienceDialog() {
    final companyController = TextEditingController();
    final positionController = TextEditingController();
    final locationController = TextEditingController();
    final descController = TextEditingController();
    bool isCurrent = false;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: const Text('Add Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: companyController, decoration: _inputDecoration('Company')),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: positionController, decoration: _inputDecoration('Position')),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: locationController, decoration: _inputDecoration('Location')),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: descController, decoration: _inputDecoration('Description'), maxLines: 3),
                const SizedBox(height: AppSpacing.sm),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(startDate == null ? 'Select Start Date' : 'Start: ${startDate!.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onTap: () => _selectDate(context, startDate, (date) => setDialogState(() => startDate = date)),
                ),

                if (!isCurrent)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(endDate == null ? 'Select End Date' : 'End: ${endDate!.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                    onTap: () => _selectDate(context, endDate, (date) => setDialogState(() => endDate = date)),
                  ),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Currently Working'),
                  value: isCurrent,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setDialogState(() => isCurrent = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
              ),
              onPressed: () {
                if (companyController.text.isNotEmpty) {
                  if (startDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start Date is required')));
                    return;
                  }
                  setState(() {
                    _experience.add(ExperienceModel(
                      company: companyController.text,
                      position: positionController.text,
                      location: locationController.text,
                      description: descController.text,
                      current: isCurrent,
                      startDate: startDate,
                      endDate: endDate,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final profileState = ref.read(profileProvider);
      final profile = profileState.value;

      PreferencesModel? preferences;
      if (profile?.role.toLowerCase() == 'jobseeker') {
        preferences = PreferencesModel(
          jobTypes: _selectedJobTypes,
          expectedSalary: ExpectedSalaryModel(min: _minSalary, max: _maxSalary, currency: _currency),
          willingToRelocate: _willingToRelocate,
          availableFrom: _availableFrom,
        );
      }

      await ref.read(profileRepositoryProvider).updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        skills: profile?.role.toLowerCase() == 'jobseeker' ? _skills : null,
        education: profile?.role.toLowerCase() == 'jobseeker' ? _education : null,
        experience: profile?.role.toLowerCase() == 'jobseeker' ? _experience : null,
        preferences: preferences,
      );

      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAvatarUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(profileRepositoryProvider).uploadAvatar(file);
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Avatar Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCVUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickMedia();
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(profileRepositoryProvider).uploadCV(file);
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _handleDeleteCV() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(profileRepositoryProvider).deleteCV();
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}