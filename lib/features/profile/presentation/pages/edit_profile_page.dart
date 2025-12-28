import 'package:flutter/material.dart';
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

  // Basic profile controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  // JobSeeker data lists
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
      // Basic profile
      _firstNameController.text = profile.profile?.firstName ?? '';
      _lastNameController.text = profile.profile?.lastName ?? '';
      _phoneController.text = profile.profile?.phone ?? '';
      _bioController.text = profile.profile?.bio ?? '';
      _cityController.text = profile.profile?.location?.city ?? '';
      _countryController.text = profile.profile?.location?.country ?? '';

      // JobSeeker data
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
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (profile) {
          _populateControllers(profile);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Picture
                _buildProfilePictureSection(profile),
                const SizedBox(height: 32),

                // Basic Info Section
                _buildBasicInfoSection(),
                const SizedBox(height: 24),

                // CV Section (JobSeekers only)
                if (profile.role.toLowerCase() == 'jobseeker') ...[
                  _buildCVSection(profile),
                  const SizedBox(height: 24),

                  // Skills Section
                  _buildSkillsSection(),
                  const SizedBox(height: 24),

                  // Education Section
                  _buildEducationSection(),
                  const SizedBox(height: 24),

                  // Experience Section
                  _buildExperienceSection(),
                  const SizedBox(height: 24),

                  // Preferences Section
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
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: (profile.profile?.avatar != null && profile.profile!.avatar!.isNotEmpty)
                ? NetworkImage(profile.profile!.avatar!)
                : null,
            child: (profile.profile?.avatar == null || profile.profile!.avatar!.isEmpty)
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                onPressed: _isLoading ? null : _handleAvatarUpload,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _countryController,
          decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildCVSection(ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('Resume / CV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (profile.jobSeekerProfile?.resume != null && profile.jobSeekerProfile!.resume!['url'] != null)
          ListTile(
            tileColor: Colors.blue.withOpacity(0.05),
            leading: const Icon(Icons.description, color: Colors.blue),
            title: Text(
              profile.jobSeekerProfile!.resume!['filename'] ?? 'Resume.pdf',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.grey),
                  onPressed: () async {
                    final url = profile.jobSeekerProfile!.resume!['url'];
                    if (url != null) await launchUrl(Uri.parse(url));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _isLoading ? null : _handleDeleteCV,
                ),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          )
        else
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleCVUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Resume'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => _showAddSkillDialog(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_skills.isEmpty)
          const Text('No skills added yet', style: TextStyle(color: Colors.grey))
        else
          ..._skills.map((skill) => Card(
            child: ListTile(
              title: Text(skill.name),
              subtitle: Text('Level: ${skill.level}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => _skills.remove(skill)),
              ),
            ),
          )),
      ],
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Education', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => _showAddEducationDialog(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_education.isEmpty)
          const Text('No education added yet', style: TextStyle(color: Colors.grey))
        else
          ..._education.map((edu) => Card(
            child: ListTile(
              title: Text(edu.degree),
              subtitle: Text('${edu.institution}\n${edu.fieldOfStudy}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
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
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () => _showAddExperienceDialog(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_experience.isEmpty)
          const Text('No experience added yet', style: TextStyle(color: Colors.grey))
        else
          ..._experience.map((exp) => Card(
            child: ListTile(
              title: Text(exp.position),
              subtitle: Text('${exp.company}\n${exp.location ?? ""}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
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
        const Divider(),
        const Text('Job Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // Job Types
        const Text('Preferred Job Types', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['full-time', 'part-time', 'contract', 'internship', 'freelance'].map((type) {
            return FilterChip(
              label: Text(type),
              selected: _selectedJobTypes.contains(type),
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
        const SizedBox(height: 16),

        // Expected Salary
        const Text('Expected Salary', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue: _minSalary?.toString(),
                onChanged: (v) => _minSalary = int.tryParse(v),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Max', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue: _maxSalary?.toString(),
                onChanged: (v) => _maxSalary = int.tryParse(v),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _currency,
              items: ['USD', 'EUR', 'GBP', 'XAF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _currency = v!),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Willing to Relocate
        SwitchListTile(
          title: const Text('Willing to Relocate'),
          value: _willingToRelocate,
          onChanged: (v) => setState(() => _willingToRelocate = v),
        ),
      ],
    );
  }

  // Dialog for adding a skill
  void _showAddSkillDialog() {
    final nameController = TextEditingController();
    String selectedLevel = 'beginner';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Skill Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLevel,
                decoration: const InputDecoration(labelText: 'Proficiency Level', border: OutlineInputBorder()),
                items: ['beginner', 'intermediate', 'advanced', 'expert']
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (v) => setState(() => selectedLevel = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
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

  // Dialog for adding education
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
          title: const Text('Add Education'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: institutionController, decoration: const InputDecoration(labelText: 'Institution')),
                const SizedBox(height: 8),
                TextField(controller: degreeController, decoration: const InputDecoration(labelText: 'Degree')),
                const SizedBox(height: 8),
                TextField(controller: fieldController, decoration: const InputDecoration(labelText: 'Field of Study')),
                const SizedBox(height: 8),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 8),

                // --- Start Date Picker ---
                ListTile(
                  title: Text(startDate == null ? 'Select Start Date' : 'Start: ${startDate!.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, startDate, (date) => setDialogState(() => startDate = date)),
                ),

                // --- End Date Picker (Hide if current) ---
                if (!isCurrent)
                  ListTile(
                    title: Text(endDate == null ? 'Select End Date' : 'End: ${endDate!.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, endDate, (date) => setDialogState(() => endDate = date)),
                  ),

                CheckboxListTile(
                  title: const Text('Currently Studying'),
                  value: isCurrent,
                  onChanged: (v) => setDialogState(() => isCurrent = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (institutionController.text.isNotEmpty) {
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
                }else {
                  // Show a small warning if date is missing
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start Date is required')));
                }

              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for adding experience
  void _showAddExperienceDialog() {
    final companyController = TextEditingController();
    final positionController = TextEditingController();
    final locationController = TextEditingController();
    final descController = TextEditingController();
    bool isCurrent = false;
    DateTime? startDate; // Change this to local state inside the dialog
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company')),
                const SizedBox(height: 8),
                TextField(controller: positionController, decoration: const InputDecoration(labelText: 'Position')),
                const SizedBox(height: 8),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 8),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                const SizedBox(height: 8),
                // --- Start Date Picker ---
                ListTile(
                  title: Text(startDate == null ? 'Select Start Date' : 'Start: ${startDate!.toLocal().toString().split(' ')[0]}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, startDate, (date) => setDialogState(() => startDate = date)),
                ),

                // --- End Date Picker (Hide if current) ---
                if (!isCurrent)
                  ListTile(
                    title: Text(endDate == null ? 'Select End Date' : 'End: ${endDate!.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, endDate, (date) => setDialogState(() => endDate = date)),
                  ),

                CheckboxListTile(
                  title: const Text('Currently Working'),
                  value: isCurrent,
                  onChanged: (v) => setDialogState(() => isCurrent = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (companyController.text.isNotEmpty) {
                  setState(() {
                    _experience.add(ExperienceModel(
                      company: companyController.text,
                      position: positionController.text,
                      location: locationController.text,
                      description: descController.text,
                      current: isCurrent,
                      startDate: startDate, // Now this is passed correctly
                      endDate: endDate,
                    ));
                  });
                  Navigator.pop(context);
                }else if (startDate == null) {
                  // Show a small warning if date is missing
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start Date is required')));
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
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
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