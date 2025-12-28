// lib/features/profile/presentation/pages/deposit_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/balance_provider.dart';
import '../../data/repositories/payment_repository.dart';
import '../../../../core/utils/logger.dart';

class DepositPage extends ConsumerStatefulWidget {
  final String? initialAmount;
  const DepositPage({super.key, this.initialAmount});

  @override
  ConsumerState<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends ConsumerState<DepositPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _phoneController = TextEditingController();
  String _selectedMethod = 'mtn'; // Default to MTN
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }


  Future<void> _handleDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    try {
      final amount = double.parse(_amountController.text);
      final phoneNumber = _phoneController.text; // Get the number from the controller

      final repository = ref.read(paymentRepositoryProvider);

      // Pass the required fields to the repository
      await repository.initializeDeposit(
        amount: amount,
        phoneNumber: phoneNumber,
        paymentMethod: _selectedMethod, // 'mtn' or 'orange'
      );

      if (mounted) {
        _showSuccessDialog(amount);
      }
    } catch (e) {
      AppLogger.error('Deposit failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deposit failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Initiated'),
        content: Text('Please check your phone to confirm the transaction of ${amount.toStringAsFixed(0)} XAF.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              ref.invalidate(balanceProvider); // Refresh balance
              context.go('/profile/balance'); // Return to balance page
            },
            child: const Text('I have confirmed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Up Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Method Selection
              const Text('Select Provider', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildMethodCard('mtn', 'MTN Mobile Money', Colors.yellow[700]!),
              _buildMethodCard('orange', 'Orange Money', Colors.orange[800]!),

              const SizedBox(height: 24),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (XAF)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter amount' : null,
              ),

              const SizedBox(height: 16),

              // Phone Input
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '6XXXXXXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter phone number' : null,
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isProcessing ? null : _handleDeposit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Top Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard(String id, String label, Color color) {
    bool isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? color : Colors.grey.withOpacity(0.3), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(Icons.payment, color: color),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}