import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/marketplace_repository.dart';
import '../widgets/image_picker_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/logger.dart';

class CreateProductPage extends ConsumerStatefulWidget {
  const CreateProductPage({super.key});

  @override
  ConsumerState<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends ConsumerState<CreateProductPage>
    with WidgetsBindingObserver {
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
  int _quantity = 1;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  Position? _currentPosition;
  String? _locationError;
  bool _isRequestingLocation = false;
  int _locationAttempts = 0;
  static const int _maxLocationAttempts = 2;

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
    if (state == AppLifecycleState.resumed) {
      // Re-check location when returning from settings
      _requestLocation();
    }
  }

  Future<void> _requestLocation() async {
    if (_isRequestingLocation) return;

    setState(() {
      _isRequestingLocation = true;
      _locationError = null;
    });

    // Try to get last known position first (faster)
    final lastPosition = await _getLastKnownPosition();
    if (lastPosition != null && mounted) {
      setState(() {
        _currentPosition = lastPosition;
        _isRequestingLocation = false;
        _locationError = null;
      });
      AppLogger.info('Using last known position: ${lastPosition.latitude}, ${lastPosition.longitude}');
      return;
    }

    // If no last known position, get current position
    final position = await _determinePosition();

    if (mounted) {
      setState(() {
        _isRequestingLocation = false;
        if (position != null) {
          _currentPosition = position;
          _locationError = null;
          _locationAttempts = 0;
        } else {
          _locationAttempts++;
        }
      });
    }
  }

  Future<Position?> _getLastKnownPosition() async {
    try {
      // Check permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final lastPosition = await Geolocator.getLastKnownPosition();

      // Only use last known position if it's recent (within 30 minutes)
      if (lastPosition != null) {
        final age = DateTime.now().difference(lastPosition.timestamp);
        if (age.inMinutes < 30) {
          return lastPosition;
        }
      }

      return null;
    } catch (e) {
      AppLogger.debug('Could not get last known position: $e');
      return null;
    }
  }

  Future<Position?> _determinePosition() async {
    try {
      // Check if location repositories are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warn('Location repositories are disabled.');
        if (mounted) {
          setState(() => _locationError =
          'Location repositories are disabled. Please enable location in your device settings.');
        }
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warn('Location permissions are denied.');
          if (mounted) {
            setState(() => _locationError =
            'Location permission denied. Please allow location access to list products.');
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warn('Location permissions are permanently denied.');
        if (mounted) {
          setState(() => _locationError =
          'Location permission permanently denied. Please enable it in app settings.');
        }
        return null;
      }

      // Get current position with flexible timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: _locationAttempts > 0
              ? LocationAccuracy.medium  // Use lower accuracy on retry
              : LocationAccuracy.high,
          distanceFilter: 0,
          forceLocationManager: _locationAttempts > 0,  // Try LocationManager on retry
          timeLimit: Duration(seconds: _locationAttempts > 0 ? 15 : 10),
        ),
      ).timeout(
        Duration(seconds: _locationAttempts > 0 ? 20 : 15),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      AppLogger.debug('Got device position: ${position.latitude}, ${position.longitude}');
      return position;
    } on TimeoutException catch (e) {
      AppLogger.error('Location request timed out', error: e);
      if (mounted) {
        setState(() => _locationError =
        'Location request timed out. Please ensure GPS is enabled and you have a clear view of the sky.');
      }
      return null;
    } catch (e, st) {
      AppLogger.error('Error determining position', error: e, stackTrace: st);
      if (mounted) {
        setState(() => _locationError =
        'Unable to get location. Please check your settings and try again.');
      }
      return null;
    }
  }

  Future<void> _submitProduct() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check for images
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one image.'),
          backgroundColor: Colors.orange,
        ),
      );
      AppLogger.warn('No images selected.');
      return;
    }

    // Check for location
    if (_currentPosition == null) {
      if (_locationAttempts < _maxLocationAttempts) {
        // Show dialog asking to retry
        final retry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Required'),
            content: const Text(
              'We need your location to list your product. Would you like to try getting your location again?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Retry'),
              ),
            ],
          ),
        );

        if (retry == true) {
          await _requestLocation();
          if (_currentPosition != null) {
            // Retry submission
            _submitProduct();
          }
        }
      } else {
        // Allow manual entry after max attempts
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Unavailable'),
            content: const Text(
              'Unable to get your location automatically. Your product will be listed with the city you entered. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (proceed != true) return;
      }
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic>? coordinates;

      if (_currentPosition != null) {
        coordinates = {
          'type': 'Point',
          'coordinates': [_currentPosition!.longitude, _currentPosition!.latitude]
        };
        AppLogger.debug('Using coordinates: ${coordinates['coordinates']}');
      } else {
        AppLogger.warn('Submitting product without GPS coordinates');
      }

      final repository = ref.read(marketplaceRepositoryProvider);
      await repository.createProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        price: double.parse(_priceController.text),
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

      AppLogger.info('Product listed successfully: ${_nameController.text}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product listed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e, st) {
      AppLogger.error('Error submitting product', error: e, stackTrace: st);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to list product: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
        title: const Text('Sell Product'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Location Status Indicator
                if (_currentPosition != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location acquired: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_currentPosition != null) const SizedBox(height: 16),

                // Image Picker
                ImagePickerWidget(
                  images: _selectedImages,
                  onImagesSelected: (images) {
                    setState(() {
                      _selectedImages = images.map((f) => XFile(f.path)).toList();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g., iPhone 13 Pro',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Product name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Product name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Electronics',
                    'Fashion',
                    'Home & Garden',
                    'Sports',
                    'Books',
                    'Other'
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) => setState(() => _category = value!),
                ),
                const SizedBox(height: 16),

                // Price
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (XAF) *',
                    hintText: 'e.g., 50000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  title: const Text('Price is negotiable'),
                  value: _negotiable,
                  onChanged: (value) => setState(() => _negotiable = value!),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Provide details about the product...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Condition
                DropdownButtonFormField<String>(
                  value: _condition,
                  decoration: const InputDecoration(
                    labelText: 'Condition *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    {'value': 'new', 'label': 'New'},
                    {'value': 'like_new', 'label': 'Like New'},
                    {'value': 'good', 'label': 'Good'},
                    {'value': 'fair', 'label': 'Fair'},
                    {'value': 'poor', 'label': 'Poor'},
                  ].map((c) => DropdownMenuItem(
                    value: c['value'],
                    child: Text(c['label']!),
                  )).toList(),
                  onChanged: (value) => setState(() => _condition = value!),
                ),
                const SizedBox(height: 16),

                // City
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    hintText: 'e.g., Douala',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'City is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Delivery Options
                const Text(
                  'Delivery Options',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  title: const Text('Can ship'),
                  subtitle: const Text('You can deliver this item'),
                  value: _canShip,
                  onChanged: (value) => setState(() => _canShip = value!),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                CheckboxListTile(
                  title: const Text('Pickup available'),
                  subtitle: const Text('Buyer can pick up in person'),
                  value: _pickupAvailable,
                  onChanged: (value) => setState(() => _pickupAvailable = value!),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 16),

                // Quantity
                TextFormField(
                  initialValue: '$_quantity',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity *',
                    hintText: 'e.g., 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (newValue) {
                    final qty = int.tryParse(newValue ?? '');
                    if (qty == null || qty < 1) {
                      return 'Quantity must be at least 1';
                    }
                    return null;
                  },
                  onChanged: (newValue) {
                    final qty = int.tryParse(newValue);
                    if (qty != null && qty > 0) {
                      _quantity = qty;
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'List Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Error overlay for location issues
          if (_locationError != null)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: CustomErrorWidget(
                  message: _locationError!,
                  onRetry: _isRequestingLocation ? null : _requestLocation,
                ),
              ),
            ),

          // Loading overlay for location request
          if (_isRequestingLocation && _currentPosition == null)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Getting your location...',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}