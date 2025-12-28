// Category Chips
// =====================================================
// MARKETPLACE WIDGETS
// lib/features/marketplace/presentation/widgets/category_chips.dart
// =====================================================
import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
final List<String> categories;
final String? selectedCategory;
final Function(String?) onSelected;

const CategoryChips({
super.key,
required this.categories,
this.selectedCategory,
required this.onSelected,
});

@override
Widget build(BuildContext context) {
return SizedBox(
height: 50,
child: ListView(
scrollDirection: Axis.horizontal,
children: [
FilterChip(
label: const Text('All'),
selected: selectedCategory == null,
onSelected: (_) => onSelected(null),
),
const SizedBox(width: 8),
...categories.map((category) {
return Padding(
padding: const EdgeInsets.only(right: 8),
child: FilterChip(
label: Text(category),
selected: selectedCategory == category,
onSelected: (_) => onSelected(category),
),
);
}).toList(),
],
),
);
}
}
