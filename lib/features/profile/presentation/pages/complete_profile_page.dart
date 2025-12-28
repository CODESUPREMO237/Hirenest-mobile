import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/auth_service.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isLoading = false;
  XFile? _profileImage;

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _profileImage = image);
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);

    try {
      // Upload profile picture if selected
      if (_profileImage != null) {
        await authService.updateProfilePicture(_profileImage!.path);
      }

      // Update backend profile
      await authService.updateProfile({
        'profile.phone': _phoneController.text,
        'profile.bio': _bioController.text,
        'profile.location.city': _cityController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile completed successfully!')),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImage != null
                          ? FileImage(File(_profileImage!.path))
                          : null,
                      child: _profileImage == null
                          ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickProfileImage,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // City
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Complete Button
              ElevatedButton(
                onPressed: _isLoading ? null : _completeProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
