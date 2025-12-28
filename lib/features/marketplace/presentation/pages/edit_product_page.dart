// Edit Product Page
// =====================================================
// lib/features/marketplace/presentation/pages/edit_product_page.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/marketplace_repository.dart';
import '../providers/product_detail_provider.dart';

class EditProductPage extends ConsumerStatefulWidget {
  final String productId;

  const EditProductPage({super.key, required this.productId});

  @override
  ConsumerState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends ConsumerState<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  void _loadProduct() {
    ref.read(productDetailProvider(widget.productId)).whenData((product) {
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.amount.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(marketplaceRepositoryProvider).updateProduct(
        widget.productId,
        {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price[amount]': double.parse(_priceController.text),
          // You can add other fields here if needed
        },
      );


      ref.invalidate(productDetailProvider(widget.productId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}