import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../widgets/image_picker_widget.dart';
import '../../../../core/widgets/error_widget.dart';

class CreateProductPage extends ConsumerStatefulWidget {
  const CreateProductPage({super.key});
  @override
  ConsumerState<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends ConsumerState<CreateProductPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  String _category = 'Electronics';
  String _condition = 'good';
  bool _negotiable = false;
  bool _canShip = true;
  bool _pickupAvailable = true;
  final int _quantity = 1;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  Position? _currentPosition;
  String? _locationError;
  bool _isRequestingLocation = false;
  // Location retry fields removed (unused)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestLocation();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _requestLocation();
  }

  Future<void> _requestLocation() async {
    if (_isRequestingLocation) return;
    setState(() { _isRequestingLocation = true; _locationError = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location disabled');
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw Exception('Permission denied');
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() { _currentPosition = pos; _isRequestingLocation = false; _locationError = null; });
    } catch (e) {
      if (mounted) setState(() { _isRequestingLocation = false; _locationError = 'Unable to get location.'; });
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate() || _selectedImages.isEmpty) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? coordinates = _currentPosition != null ? {'type': 'Point', 'coordinates': [_currentPosition!.longitude, _currentPosition!.latitude]} : null;
      await ref.read(marketplaceRepositoryProvider).createProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        price: double.parse(_priceController.text.trim()),
        currency: 'XAF',
        negotiable: _negotiable,
        condition: _condition,
        city: _cityController.text.trim(),
        country: 'Cameroon',
        canShip: _canShip,
        pickupAvailable: _pickupAvailable,
        quantity: _quantity,
        images: _selectedImages,
        coordinates: coordinates,
      );
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listed!'), backgroundColor: AppColors.success)); context.pop(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Sell Product'), elevation: 0),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (_currentPosition != null)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: AppSpacing.roundedSm),
                    child: Row(children: [const Icon(Icons.location_on, color: AppColors.success), const SizedBox(width: AppSpacing.sm), Text('Location acquired', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.successDark))]),
                  ),
                const SizedBox(height: AppSpacing.lg),
                ImagePickerWidget(images: _selectedImages, onImagesSelected: (images) => setState(() => _selectedImages = images.map((f) => XFile(f.path)).toList())),
                const SizedBox(height: AppSpacing.lg),
                _buildTextField('Product Name', _nameController, isRequired: true),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: AppSpacing.roundedSm)),
                  items: ['Electronics', 'Fashion', 'Home & Garden', 'Sports', 'Books', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildTextField('Price (XAF)', _priceController, isRequired: true, isNumber: true),
                CheckboxListTile(title: const Text('Negotiable'), value: _negotiable, onChanged: (v) => setState(() => _negotiable = v!), controlAffinity: ListTileControlAffinity.leading),
                const SizedBox(height: AppSpacing.md),
                _buildTextField('Description', _descriptionController, isRequired: true, maxLines: 4),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _condition,
                  decoration: InputDecoration(labelText: 'Condition', border: OutlineInputBorder(borderRadius: AppSpacing.roundedSm)),
                  items: [{'v':'new','l':'New'}, {'v':'like_new','l':'Like New'}, {'v':'good','l':'Good'}, {'v':'fair','l':'Fair'}, {'v':'poor','l':'Poor'}].map((c) => DropdownMenuItem(value: c['v'], child: Text(c['l']!))).toList(),
                  onChanged: (v) => setState(() => _condition = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildTextField('City', _cityController, isRequired: true),
                const SizedBox(height: AppSpacing.lg),
                Text('Delivery Options', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                CheckboxListTile(title: const Text('Can ship'), value: _canShip, onChanged: (v) => setState(() => _canShip = v!), controlAffinity: ListTileControlAffinity.leading),
                CheckboxListTile(title: const Text('Pickup available'), value: _pickupAvailable, onChanged: (v) => setState(() => _pickupAvailable = v!), controlAffinity: ListTileControlAffinity.leading),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd)),
                  child: _isLoading ? const CircularProgressIndicator(color: AppColors.white) : const Text('List Product'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          if (_locationError != null) Positioned(top: 0, left: 16, right: 16, child: Material(elevation: 4, borderRadius: AppSpacing.roundedSm, child: CustomErrorWidget(message: _locationError!, onRetry: _isRequestingLocation ? null : _requestLocation))),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isRequired = false, bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: AppSpacing.roundedSm)),
      validator: (v) => (isRequired && (v == null || v.trim().isEmpty)) ? 'Required' : null,
    );
  }
}
