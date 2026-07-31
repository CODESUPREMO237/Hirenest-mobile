// =====================================================
// PAYOUT PAGE (MODERN UI)
// lib/features/profile/presentation/pages/payout_page.dart
// =====================================================
import 'package:flutter/material.dart';
import '../../../../core/widgets/error_widget.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
  String _selectedMomoProvider = 'mtn';
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Request Payout'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryLight,
        centerTitle: true,
      ),
      body: balanceAsync.when(
        data: (balance) => SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppSpacing.roundedXl,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Available Balance',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'XAF ${balance.availableForWithdrawal.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                Text(
                  'Withdrawal Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: const Icon(Icons.money, color: AppColors.primary),
                    suffixIcon: TextButton(
                      onPressed: () {
                        _amountController.text = balance.availableForWithdrawal.toStringAsFixed(2);
                      },
                      child: const Text('MAX', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedLg,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedLg,
                      borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.roundedLg,
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an amount';
                    final amount = double.tryParse(value);
                    if (amount == null) return 'Please enter a valid amount';
                    if (amount <= 0) return 'Amount must be greater than 0';
                    if (amount > balance.availableForWithdrawal) return 'Insufficient balance';
                    if (amount < 500) return 'Minimum withdrawal is 500 XAF';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xxl),

                Text(
                  'Transfer Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Expanded(child: _buildMethodCard('momo', 'Mobile Money', Icons.phone_android)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildMethodCard('bank', 'Bank Transfer', Icons.account_balance)),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedMethod == 'momo' ? _buildMomoForm() : _buildBankForm(),
                ),

                const SizedBox(height: AppSpacing.xxl),

                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: AppSpacing.roundedLg,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.roundedLg,
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            'Request Withdrawal',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Important Information',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('• Minimum withdrawal: 500 XAF', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight, height: 1.5)),
                      Text('• Processing time: Under 1 hour', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight, height: 1.5)),
                      Text('• Withdrawals are processed Monday-Friday', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight, height: 1.5)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => CustomErrorWidget(error: error),
      ),
    );
  }

  Widget _buildMethodCard(String value, String label, IconData icon) {
    final isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [] : AppSpacing.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMutedLight,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.textMutedLight),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedLg,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedLg,
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedLg,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator ?? (v) => v?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildMomoProviderCard(String value, String imagePath) {
    final isSelected = _selectedMomoProvider == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedMomoProvider = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
          borderRadius: AppSpacing.roundedLg,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [] : AppSpacing.cardShadow,
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Text(
              value.toUpperCase(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMomoForm() {
    return Column(
      key: const ValueKey('momo_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Select Provider', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildMomoProviderCard('mtn', 'assets/images/mtn_logo.png')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildMomoProviderCard('orange', 'assets/images/orange_logo.png')),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildModernTextField(
          controller: _momoNumberController,
          labelText: 'Mobile Money Number',
          hintText: '+237 XXX XXX XXX',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Phone number is required';
            if (v.replaceAll(RegExp(r'\D'), '').length < 9) return 'Enter a valid phone number';
            return null;
          }
        ),
        const SizedBox(height: AppSpacing.md),
        _buildModernTextField(
          controller: _momoNameController,
          labelText: 'Account Name',
          icon: Icons.person_outline,
          validator: (v) => v == null || v.trim().isEmpty ? 'Account name is required' : null,
        ),
      ],
    );
  }

  Widget _buildBankForm() {
    return Column(
      key: const ValueKey('bank_form'),
      children: [
        _buildModernTextField(
          controller: _accountNumberController,
          labelText: 'Account Number',
          icon: Icons.numbers,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildModernTextField(
          controller: _accountNameController,
          labelText: 'Account Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildModernTextField(
          controller: _bankNameController,
          labelText: 'Bank Name',
          icon: Icons.account_balance_outlined,
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
          'provider': _selectedMomoProvider,
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
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.success),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('Success', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Your withdrawal request of XAF ${amount.toStringAsFixed(2)} has been submitted. '
                  'It will be processed within 1-3 business days.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.white),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text('Withdrawal failed: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}