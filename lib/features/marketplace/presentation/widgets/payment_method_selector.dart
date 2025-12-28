// Payment Method Selector
// =====================================================
// lib/features/marketplace/presentation/widgets/payment_method_selector.dart
// =====================================================
import 'package:flutter/material.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String? selectedMethod;
  final Function(String) onSelected;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'id': 'momo', 'name': 'Mobile Money', 'icon': Icons.phone_android},
      {'id': 'card', 'name': 'Credit Card', 'icon': Icons.credit_card},
      {'id': 'bank', 'name': 'Bank Transfer', 'icon': Icons.account_balance},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...methods.map((method) {
          return RadioListTile<String>(
            value: method['id'] as String,
            groupValue: selectedMethod,
            onChanged: (value) => onSelected(value!),
            title: Text(method['name'] as String),
            secondary: Icon(method['icon'] as IconData),
          );
        }).toList(),
      ],
    );
  }
}