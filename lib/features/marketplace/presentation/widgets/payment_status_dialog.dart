// Payment Status Dialog
// =====================================================
// lib/features/marketplace/presentation/widgets/payment_status_dialog.dart
// =====================================================
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentStatusDialog extends StatelessWidget {
  final bool success;
  final String message;
  final VoidCallback? onDone;

  const PaymentStatusDialog({
    super.key,
    required this.success,
    required this.message,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? AppColors.success : AppColors.error,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            success ? 'Success!' : 'Failed',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDone?.call();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}