// lib/features/marketplace/presentation/widgets/product_filters_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/products_state.dart';
import '../providers/PaginatedProductsNotifier.dart';

class ProductFiltersWidget extends ConsumerStatefulWidget {
  const ProductFiltersWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductFiltersWidget> createState() => _ProductFiltersWidgetState();
}

class _ProductFiltersWidgetState extends ConsumerState<ProductFiltersWidget> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedCondition;
  double? _minPrice;
  double? _maxPrice;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';
  bool _availableOnly = false;

  @override
  void initState() {
    super.initState();
    // Sync local UI with the actual provider state
    final currentFilters = ref.read(paginatedProductsProvider).value?.filters;
    if (currentFilters != null) {
      _searchController.text = currentFilters.search ?? '';
      _selectedCategory = currentFilters.category;
      _selectedCondition = currentFilters.condition;
      _minPrice = currentFilters.minPrice;
      _maxPrice = currentFilters.maxPrice;
      _sortBy = currentFilters.sortBy ?? 'createdAt';
      _sortOrder = currentFilters.sortOrder ?? 'desc';
      _availableOnly = currentFilters.availableOnly ?? false;
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = ProductFilters(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      category: _selectedCategory,
      condition: _selectedCondition,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      availableOnly: _availableOnly,
    );

    ref.read(paginatedProductsProvider.notifier).applyFilters(filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedCondition = null;
      _minPrice = null;
      _maxPrice = null;
      _sortBy = 'createdAt';
      _sortOrder = 'desc';
      _availableOnly = false;
    });

    ref.read(paginatedProductsProvider.notifier).clearFilters();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Products',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Categories')),
                  DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                  DropdownMenuItem(value: 'Fashion', child: Text('Fashion')),
                  DropdownMenuItem(value: 'Home', child: Text('Home & Garden')),
                  DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                  DropdownMenuItem(value: 'Books', child: Text('Books')),
                  DropdownMenuItem(value: 'Toys', child: Text('Toys')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 16),

              // Condition
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Conditions')),
                  DropdownMenuItem(value: 'new', child: Text('New')),
                  DropdownMenuItem(value: 'like new', child: Text('Like New')),
                  DropdownMenuItem(value: 'good', child: Text('Good')),
                  DropdownMenuItem(value: 'fair', child: Text('Fair')),
                  DropdownMenuItem(value: 'poor', child: Text('Poor')),
                ],
                onChanged: (value) => setState(() => _selectedCondition = value),
              ),
              const SizedBox(height: 16),

              // Price Range
              Text(
                'Price Range',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Min Price',
                        prefixText: '\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _minPrice = double.tryParse(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Max Price',
                        prefixText: '\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _maxPrice = double.tryParse(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sort By
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: InputDecoration(
                  labelText: 'Sort By',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'createdAt', child: Text('Date Added')),
                  DropdownMenuItem(value: 'price.amount', child: Text('Price')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'views', child: Text('Popularity')),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              const SizedBox(height: 16),

              // Sort Order
              DropdownButtonFormField<String>(
                value: _sortOrder,
                decoration: InputDecoration(
                  labelText: 'Sort Order',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                  DropdownMenuItem(value: 'desc', child: Text('Descending')),
                ],
                onChanged: (value) => setState(() => _sortOrder = value!),
              ),
              const SizedBox(height: 16),

              // Available Only
              SwitchListTile(
                title: const Text('Show Available Only'),
                value: _availableOnly,
                onChanged: (value) => setState(() => _availableOnly = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Clear Filters'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Usage: Show filter bottom sheet
void showProductFilters(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ProductFiltersWidget(),
  );
}