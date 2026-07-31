// lib/features/company/presentation/pages/edit_company_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/widgets/error_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../providers/company_provider.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/models/company_model.dart';

class EditCompanyPage extends ConsumerStatefulWidget {
  const EditCompanyPage({super.key});

  @override
  ConsumerState<EditCompanyPage> createState() => _EditCompanyPageState();
}

class _EditCompanyPageState extends ConsumerState<EditCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _websiteController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _addressController;

  String? _selectedIndustry;
  String? _selectedCompanySize;
  File? _logoFile;
  File? _bannerFile;
  bool _isLoading = false;
  CompanyModel? _company;

  final List<String> _industries = [
    'Technology', 'Healthcare', 'Finance', 'Education', 'Retail',
    'Manufacturing', 'Construction', 'Hospitality', 'Transportation', 'Other',
  ];

  final List<String> _companySizes = [
    '1-10', '11-50', '51-200', '201-500', '501-1000', '1000+',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _websiteController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController();
    _addressController = TextEditingController();
  }

  void _loadCompanyData(CompanyModel company) {
    _company = company;
    _nameController.text = company.name;
    _descriptionController.text = company.description ?? '';
    _websiteController.text = company.website ?? '';
    _emailController.text = company.email ?? '';
    _phoneController.text = company.contactPhone ?? '';
    _selectedIndustry = company.industry;
    _selectedCompanySize = company.companySize;

    if (company.locations != null && company.locations!.isNotEmpty) {
      final location = company.locations!.first;
      _cityController.text = location.city;
      _stateController.text = location.state ?? '';
      _countryController.text = location.country;
      _addressController.text = location.address ?? '';
    }
  }

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
    if (!_formKey.currentState!.validate() || _company == null) return;
    setState(() => _isLoading = true);

    try {
      final locationsList = [
        {
          'city': _cityController.text,
          'state': _stateController.text,
          'country': _countryController.text,
          'address': _addressController.text,
          'isPrimary': true,
        }
      ];

      final formData = FormData.fromMap({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'industry': _selectedIndustry,
        'companySize': _selectedCompanySize,
        'website': _websiteController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'locations': jsonEncode(locationsList),
        if (_logoFile != null) 'logo': await MultipartFile.fromFile(_logoFile!.path, filename: 'logo.jpg'),
        if (_bannerFile != null) 'banner': await MultipartFile.fromFile(_bannerFile!.path, filename: 'banner.jpg'),
      });

      final repository = ref.read(companyRepositoryProvider);
      await repository.updateCompany(_company!.id, formData);

      if (mounted) {
        ref.invalidate(myCompanyProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company updated successfully!'), backgroundColor: AppColors.success),
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
    final companyAsync = ref.watch(myCompanyProvider);
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
          'Edit Company Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/company/dashboard'),
        ),
      ),
      body: companyAsync.when(
        data: (company) {
          if (_company == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadCompanyData(company);
              setState(() {});
            });
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Column(
                  children: [
                    if (_logoFile != null)
                      CircleAvatar(radius: 50, backgroundImage: FileImage(_logoFile!))
                    else if (company.logo != null && company.logo!.isNotEmpty)
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            company.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.backgroundLight,
                              child: const Icon(Icons.business, size: 40, color: AppColors.textMutedLight),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Icon(Icons.business, size: 40, color: AppColors.textMutedLight),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    if (_bannerFile != null)
                      ClipRRect(
                        borderRadius: AppSpacing.roundedLg,
                        child: Image.file(_bannerFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
                      )
                    else if (company.banner != null && company.banner!.isNotEmpty)
                      ClipRRect(
                        borderRadius: AppSpacing.roundedLg,
                        child: Image.network(
                          company.banner!, 
                          height: 150, 
                          width: double.infinity, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 150, width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: AppSpacing.roundedLg,
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Center(child: Icon(Icons.image_outlined, size: 40, color: AppColors.textMutedLight)),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 150, width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: AppSpacing.roundedLg,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Center(child: Icon(Icons.image_outlined, size: 40, color: AppColors.textMutedLight)),
                      ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
                Center(
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.business),
                        label: Text(_logoFile != null ? 'Logo Selected' : 'Change Logo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: () => _pickImage(false),
                        icon: const Icon(Icons.image),
                        label: Text(_bannerFile != null ? 'Banner Selected' : 'Change Banner'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                  validator: (value) => value == null ? 'Required' : null,
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
                  validator: (value) => value == null ? 'Required' : null,
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
                    if (value?.isEmpty ?? true) return 'Required';
                    if (!value!.contains('@')) return 'Invalid email';
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
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (value!.length < 9 && value.length > 9) return 'Invalid phone number';
                    return null;
                  },
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
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Update Company', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => CustomErrorWidget(error: error),
      ),
    );
  }
}