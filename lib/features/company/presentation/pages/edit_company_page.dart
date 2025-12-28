// lib/features/company/presentation/pages/edit_company_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
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
        'contactEmail': _emailController.text,
        'contactPhone': _phoneController.text,
        'locations': jsonEncode(locationsList),
        if (_logoFile != null)
          'logo': await MultipartFile.fromFile(_logoFile!.path, filename: 'logo.jpg'),
        if (_bannerFile != null)
          'banner': await MultipartFile.fromFile(_bannerFile!.path, filename: 'banner.jpg'),
      });

      final repository = ref.read(companyRepositoryProvider);
      await repository.updateCompany(_company!.id, formData);

      if (mounted) {
        ref.invalidate(myCompanyProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/company/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(myCompanyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Company Profile'),
        // Manual back button if GoRouter context doesn't show it automatically
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
              padding: const EdgeInsets.all(16),
              children: [
                // PREVIEW SECTION: Logic for local vs network images
                Column(
                  children: [
                    // Logo Preview
                    if (_logoFile != null)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: FileImage(_logoFile!),
                      )
                    else if (company.logo != null)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(company.logo!),
                      ),

                    const SizedBox(height: 16),

                    // Banner Preview
                    if (_bannerFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _bannerFile!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (company.banner != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          company.banner!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),

                // Upload Buttons
                Center(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(true),
                        icon: const Icon(Icons.business),
                        label: Text(_logoFile != null ? 'Logo Selected' : 'Change Logo'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _pickImage(false),
                        icon: const Icon(Icons.image),
                        label: Text(_bannerFile != null ? 'Banner Selected' : 'Change Banner'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 4,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedIndustry,
                  decoration: const InputDecoration(
                    labelText: 'Industry *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _industries.map((industry) {
                    return DropdownMenuItem(value: industry, child: Text(industry));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedIndustry = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCompanySize,
                  decoration: const InputDecoration(
                    labelText: 'Company Size *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: _companySizes.map((size) {
                    return DropdownMenuItem(value: size, child: Text('$size employees'));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCompanySize = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.language),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (value!.length < 9 && value.length > 9) return 'Invalid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State/Province',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _countryController,
                  decoration: const InputDecoration(
                    labelText: 'Country *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.public),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Full Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Update Company', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading company: $error'),
            ],
          ),
        ),
      ),
    );
  }
}