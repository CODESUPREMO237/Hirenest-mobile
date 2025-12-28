// Categories Provider
// =====================================================
// MARKETPLACE PROVIDERS
// lib/features/marketplace/presentation/providers/categories_provider.dart
// =====================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesProvider = Provider<List<String>>((ref) {
  return [
    'Electronics',
    'Furniture',
    'Clothing',
    'Books',
    'Vehicles',
    'Real Estate',
    'Services',
    'Other',
  ];
});