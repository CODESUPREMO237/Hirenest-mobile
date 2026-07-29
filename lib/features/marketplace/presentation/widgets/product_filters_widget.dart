import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/products_state.dart';
import '../providers/paginated_products_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ProductFiltersWidget extends ConsumerStatefulWidget {
  const ProductFiltersWidget({super.key});

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

  final List<String> _categories = [
    'Electronics', 'Fashion', 'Home', 'Sports', 'Books', 'Toys', 'Other'
  ];

  final List<String> _conditions = [
    'new', 'like_new', 'good', 'fair', 'poor'
  ];

  String _formatConditionText(String condition) {
    if (condition == 'like_new') return 'Like New';
    return condition[0].toUpperCase() + condition.substring(1);
  }

  @override
  void initState() {
    super.initState();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: AppSpacing.roundedFull,
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Products',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: AppSpacing.roundedLg,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Category Chips
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = selected ? cat : null);
                          },
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedFull),
                          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.white : (isDark ? AppColors.textPrimaryLight : AppColors.textPrimaryLight),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          checkmarkColor: AppColors.white,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Condition Chips
                    Text(
                      'Condition',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _conditions.map((cond) {
                        final isSelected = _selectedCondition == cond;
                        return FilterChip(
                          label: Text(_formatConditionText(cond)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCondition = selected ? cond : null);
                          },
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedFull),
                          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.white : (isDark ? AppColors.textPrimaryLight : AppColors.textPrimaryLight),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          checkmarkColor: AppColors.white,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Price Range
                    Text(
                      'Price Range (XAF)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Min',
                              border: OutlineInputBorder(
                                borderRadius: AppSpacing.roundedLg,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _minPrice = double.tryParse(val),
                            controller: TextEditingController(text: _minPrice?.toString() ?? ''),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: Text('-'),
                        ),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Max',
                              border: OutlineInputBorder(
                                borderRadius: AppSpacing.roundedLg,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => _maxPrice = double.tryParse(val),
                            controller: TextEditingController(text: _maxPrice?.toString() ?? ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Sorting
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sortBy,
                            decoration: InputDecoration(
                              labelText: 'Sort By',
                              border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg),
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'createdAt', child: Text('Date Added')),
                              DropdownMenuItem(value: 'price.amount', child: Text('Price')),
                              DropdownMenuItem(value: 'name', child: Text('Name')),
                            ],
                            onChanged: (v) => setState(() => _sortBy = v!),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sortOrder,
                            decoration: InputDecoration(
                              labelText: 'Order',
                              border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg),
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'desc', child: Text('High/Latest')),
                              DropdownMenuItem(value: 'asc', child: Text('Low/Oldest')),
                            ],
                            onChanged: (v) => setState(() => _sortOrder = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Available Only Toggle
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: AppSpacing.roundedLg,
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: SwitchListTile(
                        title: const Text('Show Available Only', style: TextStyle(fontWeight: FontWeight.w600)),
                        value: _availableOnly,
                        onChanged: (v) => setState(() => _availableOnly = v),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        activeThumbColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _applyFilters,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
