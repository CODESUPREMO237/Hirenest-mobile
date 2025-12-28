// Category Model
// ============================================================================
// category_model.dart
// lib/features/marketplace/data/models/category_model.dart
// ============================================================================

class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final int productCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    required this.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      icon: json['icon'],
      productCount: json['productCount'] ?? 0,
    );
  }
}
