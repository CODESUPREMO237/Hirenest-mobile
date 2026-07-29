// Payment Page
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/config/app_config.dart';
import '../providers/product_detail_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final String productId;

  const PaymentPage({super.key, required this.productId});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedMethod = 'mesomb_mtn';
  bool _isProcessing = false;
  String? _orderId;
  String? _idempotencyKey;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);
    _idempotencyKey ??= const Uuid().v4();
    try {
      final paymentService = ref.read(paymentServiceProvider);
      final response = await paymentService.createPayment(
        productId: widget.productId,
        phoneNumber: _formatPhoneNumber(_phoneController.text),
        paymentMethod: _selectedMethod,
        idempotencyKey: _idempotencyKey!,
      );
      _orderId = response.orderId;
      if (mounted) {
        _pollPaymentStatus();
        _showPaymentInstructionsDialog(response.orderNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
        setState(() { _isProcessing = false; _idempotencyKey = null; });
      }
    }
  }

  Future<void> _pollPaymentStatus() async {
    if (_orderId == null) return;
    const maxAttempts = 60;
    int attempts = 0;
    while (attempts < maxAttempts && mounted) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final paymentService = ref.read(paymentServiceProvider);
        final status = await paymentService.checkPaymentStatus(_orderId!);
        if (status.paymentStatus.toLowerCase() == 'completed') {
          if (mounted) _showSuccessDialog();
          break;
        } else if (status.paymentStatus.toLowerCase() == 'failed') {
          if (mounted) _showFailureDialog();
          break;
        }
        attempts++;
      } catch (e) {
        attempts++;
      }
    }
    if (attempts >= maxAttempts && mounted) _showTimeoutDialog();
  }

  Future<void> _showPaymentInstructionsDialog(String orderNumber) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: Row(children: [Icon(Icons.phone_android, color: AppColors.primary), const SizedBox(width: AppSpacing.md), const Text('Check Your Phone')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A payment request has been sent to your ${_selectedMethod == 'mesomb_mtn' ? 'MTN' : 'Orange'} account.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppSpacing.roundedMd,
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instructions:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInstruction('1', 'Check your phone for the payment prompt'),
                  _buildInstruction('2', 'Enter your PIN to confirm'),
                  _buildInstruction('3', 'Wait for confirmation'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20, height: 20, alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.warning, borderRadius: AppSpacing.roundedFull),
            child: Text(number, style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: const Row(children: [Icon(Icons.check_circle, color: AppColors.success, size: 32), SizedBox(width: AppSpacing.md), Text('Success!')]),
        content: const Text('Your payment has been confirmed.'),
        actions: [ElevatedButton(onPressed: () => context.go('/'), child: const Text('Done'))],
      ),
    );
  }

  void _showFailureDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: const Row(children: [Icon(Icons.error_outline, color: AppColors.error, size: 32), SizedBox(width: AppSpacing.md), Text('Failed')]),
        content: const Text('Payment could not be processed.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); setState(() => _isProcessing = false); }, child: const Text('Try Again')),
          ElevatedButton(onPressed: () { Navigator.pop(context); context.pop(); }, child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showTimeoutDialog() {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
        title: const Row(children: [Icon(Icons.access_time, color: AppColors.warning, size: 32), SizedBox(width: AppSpacing.md), Text('Timeout')]),
        content: const Text('Payment request timed out.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); setState(() => _isProcessing = false); }, child: const Text('Try Again')),
          ElevatedButton(onPressed: () => context.go('/profile/orders'), child: const Text('View Orders')),
        ],
      ),
    );
  }

  String _formatPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (!phone.startsWith('237')) phone = '237$phone';
    if (!phone.startsWith('+')) phone = '+$phone';
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Payment'), elevation: 0),
      body: productAsync.when(
        data: (product) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: AppSpacing.roundedLg, boxShadow: AppSpacing.cardShadow),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          if (product.images.isNotEmpty)
                            ClipRRect(
                              borderRadius: AppSpacing.roundedSm,
                              child: Image.network(product.images.first.url, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                            ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: AppSpacing.xs),
                                Text(NumberFormat.currency(symbol: product.price.currency, decimalDigits: 0).format(product.price.amount), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.xl),
                      _buildSummaryRow('Total Amount', NumberFormat.currency(symbol: product.price.currency, decimalDigits: 0).format(product.price.amount + (product.price.amount * AppConfig.commissionRate)), isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Select Payment Method', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                _buildPaymentMethodCard('mesomb_mtn', 'MTN Mobile Money', 'Pay with MTN MOMO', AppColors.accent),
                const SizedBox(height: AppSpacing.md),
                _buildPaymentMethodCard('mesomb_orange', 'Orange Money', 'Pay with Orange Money', AppColors.warning),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Money Number',
                    hintText: '6XX XXX XXX',
                    prefixIcon: const Icon(Icons.phone),
                    prefixText: '+237 ',
                    border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                  validator: (value) => (value == null || value.length != 9 || !value.startsWith('6')) ? 'Invalid number' : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd)),
                  child: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.white)) : Text('Pay ${NumberFormat.currency(symbol: product.price.currency, decimalDigits: 0).format(product.price.amount + (product.price.amount * AppConfig.commissionRate))}'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: AppSpacing.roundedSm),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text('Your payment is secure and encrypted', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryDark))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading product: $error')),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String value, String title, String subtitle, Color color) {
    final isSelected = _selectedMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = value),
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? color : AppColors.borderLight, width: isSelected ? 2 : 1),
          borderRadius: AppSpacing.roundedMd,
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surfaceLight,
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: AppSpacing.roundedSm), child: Icon(Icons.phone_android, color: color)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight))])),
            RadioMenuButton<String>(value: value, groupValue: _selectedMethod, onChanged: (val) => setState(() => _selectedMethod = val!), child: const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, color: isTotal ? AppColors.primary : null)),
        ],
      ),
    );
  }
}
