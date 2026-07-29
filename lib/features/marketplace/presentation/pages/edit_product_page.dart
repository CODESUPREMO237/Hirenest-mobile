import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Edit Product'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppSpacing.roundedLg, boxShadow: AppSpacing.cardShadow),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Product Name', border: OutlineInputBorder(borderRadius: AppSpacing.roundedSm)),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: AppSpacing.roundedSm)),
                    maxLines: 4,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: 'Price', border: OutlineInputBorder(borderRadius: AppSpacing.roundedSm)),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd)),
              child: _isLoading ? const CircularProgressIndicator(color: AppColors.white) : const Text('Save Changes'),
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
      await ref.read(marketplaceRepositoryProvider).updateProduct(widget.productId, {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price[amount]': double.parse(_priceController.text),
      });
      ref.invalidate(productDetailProvider(widget.productId));
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated!'))); context.pop(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() { _nameController.dispose(); _descriptionController.dispose(); _priceController.dispose(); super.dispose(); }
}
