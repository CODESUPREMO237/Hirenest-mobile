// Create Company Page
// lib/features/company/presentation/pages/create_company_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
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
    'Technology',
    'Healthcare',
    'Finance',
    'Education',
    'Retail',
    'Manufacturing',
    'Construction',
    'Hospitality',
    'Transportation',
    'Other',
  ];

  final List<String> _companySizes = [
    '1-10',
    '11-50',
    '51-200',
    '201-500',
    '501-1000',
    '1000+',
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
      // Create the base map for the data
      final Map<String, dynamic> data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'industry': _selectedIndustry,
        'companySize': _selectedCompanySize,
        'website': _websiteController.text,
        'email': _emailController.text, // CHANGED from 'contactEmail' to 'email' to match backend
        'contactPhone': _phoneController.text,
      };

      final formData = FormData.fromMap(data);

      // FIX: Add locations as actual JSON fields, not a string
      // This allows the backend to parse it correctly as an array/object
      formData.fields.add(MapEntry('locations[0][city]', _cityController.text));
      formData.fields.add(MapEntry('locations[0][state]', _stateController.text));
      formData.fields.add(MapEntry('locations[0][country]', _countryController.text));
      formData.fields.add(MapEntry('locations[0][address]', _addressController.text));

      // Handle files (Existing logic is fine)
      if (_logoFile != null) {
        formData.files.add(MapEntry(
          'logo',
          await MultipartFile.fromFile(_logoFile!.path),
        ));
      }


      if (_bannerFile != null) {
        formData.files.add(MapEntry(
          'banner',
          await MultipartFile.fromFile(_bannerFile!.path),
        ));
      }

      final repository = ref.read(companyRepositoryProvider);
      await repository.createCompany(formData);

      if (mounted) {
        ref.invalidate(myCompanyProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company created successfully!'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Company Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Logo Upload
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _logoFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_logoFile!, fit: BoxFit.cover),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Upload Logo',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _pickImage(false),
                    icon: const Icon(Icons.image),
                    label: Text(_bannerFile != null ? 'Banner Selected' : 'Upload Banner'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Company Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Industry Dropdown
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
              validator: (value) => value == null ? 'Please select industry' : null,
            ),
            const SizedBox(height: 16),

            // Company Size
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
              validator: (value) => value == null ? 'Please select company size' : null,
            ),
            const SizedBox(height: 16),

            // Website
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

            // Contact Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Contact Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email';
                }
                if (!value.contains('@')) {
                  return 'Please enter valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contact Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Location Section
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
              validator: (value) => value?.isEmpty ?? true ? 'Please enter city' : null,
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
              validator: (value) => value?.isEmpty ?? true ? 'Please enter country' : null,
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

            // Submit Button
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
                  : const Text('Create Company', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}