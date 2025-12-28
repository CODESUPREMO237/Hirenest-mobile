// =====================================================
// PAYOUT PAGE
// lib/features/profile/presentation/pages/payout_page.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../providers/balance_provider.dart';
import '../providers/transactions_provider.dart';

class PayoutPage extends ConsumerStatefulWidget {
  const PayoutPage({super.key});

  @override
  ConsumerState<PayoutPage> createState() => _PayoutPageState();
}

class _PayoutPageState extends ConsumerState<PayoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _selectedMethod = 'momo';
  bool _isProcessing = false;

  // Mobile Money fields
  final _momoNumberController = TextEditingController();
  final _momoNameController = TextEditingController();

  // Bank fields
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bankNameController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _momoNumberController.dispose();
    _momoNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Payout'),
      ),
      body: balanceAsync.when(
        data: (balance) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Available Balance Card
                Card(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Available Balance'),
                        const SizedBox(height: 8),
                        Text(
                          '\$${balance.availableForWithdrawal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Amount Input
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Withdrawal Amount',
                    prefixText: 'XAF ',
                    border: const OutlineInputBorder(),
                    suffixIcon: TextButton(
                      onPressed: () {
                        _amountController.text = balance.availableForWithdrawal.toStringAsFixed(2);
                      },
                      child: const Text('Max'),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Please enter a valid amount';
                    }
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    if (amount > balance.availableForWithdrawal) {
                      return 'Insufficient balance';
                    }
                    if (amount < 500) {
                      return 'Minimum withdrawal is 500 XAF';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Payment Method Selection
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildMethodSelector('momo', 'Mobile Money', Icons.phone_android),
                _buildMethodSelector('bank', 'Bank Transfer', Icons.account_balance),

                const SizedBox(height: 24),

                // Payment Details Form
                if (_selectedMethod == 'momo') _buildMomoForm(),
                if (_selectedMethod == 'bank') _buildBankForm(),

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handleWithdrawal,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Request Withdrawal'),
                ),

                const SizedBox(height: 16),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Withdrawal Information',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('• Minimum withdrawal: \$10'),
                      Text('• Processing time: 1-3 business days'),
                      Text('• Transaction fee: 2.5% or \$1 minimum'),
                      Text('• Withdrawals are processed Monday-Friday'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildMethodSelector(String value, String label, IconData icon) {
    final isSelected = _selectedMethod == value;

    return Card(
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedMethod,
        onChanged: (val) => setState(() => _selectedMethod = val!),
        title: Text(label),
        secondary: Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      ),
    );
  }

  Widget _buildMomoForm() {
    return Column(
      children: [
        TextFormField(
          controller: _momoNumberController,
          decoration: const InputDecoration(
            labelText: 'Mobile Money Number',
            hintText: '+237 XXX XXX XXX',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _momoNameController,
          decoration: const InputDecoration(
            labelText: 'Account Name',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildBankForm() {
    return Column(
      children: [
        TextFormField(
          controller: _accountNumberController,
          decoration: const InputDecoration(
            labelText: 'Account Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _accountNameController,
          decoration: const InputDecoration(
            labelText: 'Account Name',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bankNameController,
          decoration: const InputDecoration(
            labelText: 'Bank Name',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
    );
  }

  Future<void> _handleWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);

      Map<String, dynamic> accountDetails;
      if (_selectedMethod == 'momo') {
        accountDetails = {
          'number': _momoNumberController.text,
          'name': _momoNameController.text,
        };
      } else {
        accountDetails = {
          'accountNumber': _accountNumberController.text,
          'accountName': _accountNameController.text,
          'bankName': _bankNameController.text,
        };
      }

      final request = WithdrawalRequest(
        amount: amount,
        method: _selectedMethod,
        accountDetails: accountDetails, phoneNumber: '',
      );

      await ref.read(paymentRepositoryProvider).requestWithdrawal(request.toJson());
      // Refresh balance
      ref.invalidate(balanceProvider);
      ref.invalidate(transactionsProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Success'),
              ],
            ),
            content: Text(
              'Your withdrawal request of \$${amount.toStringAsFixed(2)} has been submitted. '
                  'It will be processed within 1-3 business days.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}