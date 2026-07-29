// lib/features/company/presentation/pages/create_company_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../providers/company_provider.dart';
import '../../data/repositories/company_repository.dart';

class CreateCompanyPage extends ConsumerStatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  ConsumerState<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends ConsumerState<CreateCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedIndustry;
  String? _selectedCompanySize;
  File? _logoFile;
  File? _bannerFile;
  bool _isLoading = false;

  final List<String> _industries = [
    'Technology', 'Healthcare', 'Finance', 'Education', 'Retail',
    'Manufacturing', 'Construction', 'Hospitality', 'Transportation', 'Other',
  ];

  final List<String> _companySizes = [
    '1-10', '11-50', '51-200', '201-500', '501-1000', '1000+',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isLogo ? 500 : 1200,
      maxHeight: isLogo ? 500 : 600,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoFile = File(pickedFile.path);
        } else {
          _bannerFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'industry': _selectedIndustry,
        'companySize': _selectedCompanySize,
        'website': _websiteController.text,
        'email': _emailController.text,
        'contactPhone': _phoneController.text,
      };

      final formData = FormData.fromMap(data);

      formData.fields.add(MapEntry('locations[0][city]', _cityController.text));
      formData.fields.add(MapEntry('locations[0][state]', _stateController.text));
      formData.fields.add(MapEntry('locations[0][country]', _countryController.text));
      formData.fields.add(MapEntry('locations[0][address]', _addressController.text));

      if (_logoFile != null) {
        formData.files.add(MapEntry('logo', await MultipartFile.fromFile(_logoFile!.path)));
      }
      if (_bannerFile != null) {
        formData.files.add(MapEntry('banner', await MultipartFile.fromFile(_bannerFile!.path)));
      }

      final repository = ref.read(companyRepositoryProvider);
      await repository.createCompany(formData);

      if (mounted) {
        ref.invalidate(myCompanyProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company created successfully!'), backgroundColor: AppColors.success),
        );
        context.go('/company/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: AppColors.backgroundLight,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          'Create Company Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: AppSpacing.roundedLg,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: _logoFile != null
                          ? ClipRRect(
                              borderRadius: AppSpacing.roundedLg,
                              child: Image.file(_logoFile!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.business, size: 40, color: AppColors.textMutedLight),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Upload Logo',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: () => _pickImage(false),
                    icon: const Icon(Icons.image, color: AppColors.primary),
                    label: Text(_bannerFile != null ? 'Banner Selected' : 'Upload Banner', style: const TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            TextFormField(
              controller: _nameController,
              decoration: inputDecoration.copyWith(
                labelText: 'Company Name *',
                prefixIcon: const Icon(Icons.business, color: AppColors.textMutedLight),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter company name' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _descriptionController,
              decoration: inputDecoration.copyWith(
                labelText: 'Description *',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined, color: AppColors.textMutedLight),
                ),
              ),
              maxLines: 4,
              validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              initialValue: _selectedIndustry,
              decoration: inputDecoration.copyWith(
                labelText: 'Industry *',
                prefixIcon: const Icon(Icons.category_outlined, color: AppColors.textMutedLight),
              ),
              items: _industries.map((industry) => DropdownMenuItem(value: industry, child: Text(industry))).toList(),
              onChanged: (value) => setState(() => _selectedIndustry = value),
              validator: (value) => value == null ? 'Please select industry' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              initialValue: _selectedCompanySize,
              decoration: inputDecoration.copyWith(
                labelText: 'Company Size *',
                prefixIcon: const Icon(Icons.people_outline, color: AppColors.textMutedLight),
              ),
              items: _companySizes.map((size) => DropdownMenuItem(value: size, child: Text('$size employees'))).toList(),
              onChanged: (value) => setState(() => _selectedCompanySize = value),
              validator: (value) => value == null ? 'Please select company size' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _websiteController,
              decoration: inputDecoration.copyWith(
                labelText: 'Website',
                prefixIcon: const Icon(Icons.language, color: AppColors.textMutedLight),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _emailController,
              decoration: inputDecoration.copyWith(
                labelText: 'Contact Email *',
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMutedLight),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter email';
                if (!value.contains('@')) return 'Please enter valid email';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _phoneController,
              decoration: inputDecoration.copyWith(
                labelText: 'Contact Phone',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textMutedLight),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _cityController,
              decoration: inputDecoration.copyWith(
                labelText: 'City *',
                prefixIcon: const Icon(Icons.location_city_outlined, color: AppColors.textMutedLight),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Please enter city' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _stateController,
              decoration: inputDecoration.copyWith(
                labelText: 'State/Province',
                prefixIcon: const Icon(Icons.map_outlined, color: AppColors.textMutedLight),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _countryController,
              decoration: inputDecoration.copyWith(
                labelText: 'Country *',
                prefixIcon: const Icon(Icons.public_outlined, color: AppColors.textMutedLight),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Please enter country' : null,
            ),
            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _addressController,
              decoration: inputDecoration.copyWith(
                labelText: 'Full Address',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.location_on_outlined, color: AppColors.textMutedLight),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xxl),

            FilledButton(
              onPressed: _isLoading ? null : _submitForm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Text('Create Company', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}