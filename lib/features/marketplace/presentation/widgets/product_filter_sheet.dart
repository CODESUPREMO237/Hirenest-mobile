// Product Filter Sheet
// =====================================================
// lib/features/marketplace/presentation/widgets/product_filter_sheet.dart
// =====================================================
import 'package:flutter/material.dart';

class ProductFilterSheet extends StatefulWidget {
final String? initialCategory;
final double? initialMinPrice;
final double? initialMaxPrice;
final Function(String?, double?, double?) onApply;

const ProductFilterSheet({
super.key,
this.initialCategory,
this.initialMinPrice,
this.initialMaxPrice,
required this.onApply,
});

@override
State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
String? _category;
final _minPriceController = TextEditingController();
final _maxPriceController = TextEditingController();

@override
void initState() {
super.initState();
_category = widget.initialCategory;
_minPriceController.text = widget.initialMinPrice?.toString() ?? '';
_maxPriceController.text = widget.initialMaxPrice?.toString() ?? '';
}

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.all(20),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Filter Products',
style: Theme.of(context).textTheme.titleLarge,
),
const SizedBox(height: 20),
DropdownButtonFormField<String>(
value: _category,
decoration: const InputDecoration(labelText: 'Category'),
items: ['Electronics', 'Furniture', 'Clothing', 'Books', 'Other']
    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
    .toList(),
onChanged: (value) => setState(() => _category = value),
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: TextField(
controller: _minPriceController,
decoration: const InputDecoration(labelText: 'Min Price'),
keyboardType: TextInputType.number,
),
),
const SizedBox(width: 16),
Expanded(
child: TextField(
controller: _maxPriceController,
decoration: const InputDecoration(labelText: 'Max Price'),
keyboardType: TextInputType.number,
),
),
],
),
const SizedBox(height: 24),
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () {
setState(() {
_category = null;
_minPriceController.clear();
_maxPriceController.clear();
});
},
child: const Text('Reset'),
),
),
const SizedBox(width: 12),
Expanded(
child: ElevatedButton(
onPressed: () {
final minPrice = double.tryParse(_minPriceController.text);
final maxPrice = double.tryParse(_maxPriceController.text);
widget.onApply(_category, minPrice, maxPrice);
Navigator.pop(context);
},
child: const Text('Apply'),
),
),
],
),
],
),
);
}
}