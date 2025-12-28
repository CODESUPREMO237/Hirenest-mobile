// Payment Page
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/config/app_config.dart';
import '../providers/product_detail_provider.dart';
import '../providers/PaginatedProductsNotifier.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final String productId;

  const PaymentPage({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedMethod = 'mesomb_mtn';
  bool _isProcessing = false;
  String? _orderId;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final paymentService = ref.read(paymentServiceProvider);

      // Create payment
      final response = await paymentService.createPayment(
        productId: widget.productId,
        phoneNumber: _formatPhoneNumber(_phoneController.text),
        paymentMethod: _selectedMethod,
      );

      _orderId = response.orderId;

      if (mounted) {
        // Show payment instructions dialog
        await _showPaymentInstructionsDialog(response.orderNumber);

        // Start polling payment status
        _pollPaymentStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initiation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pollPaymentStatus() async {
    if (_orderId == null) return;

    const maxAttempts = 60; // 3 minutes (60 * 3 seconds)
    int attempts = 0;

    while (attempts < maxAttempts && mounted) {
      await Future.delayed(const Duration(seconds: 3));

      try {
        final paymentService = ref.read(paymentServiceProvider);
        final status = await paymentService.checkPaymentStatus(_orderId!);

        if (status.paymentStatus == 'completed') {
          if (mounted) {
            _showSuccessDialog();
          }
          break;
        } else if (status.paymentStatus == 'failed') {
          if (mounted) {
            _showFailureDialog();
          }
          break;
        }

        attempts++;
      } catch (e) {
        // Continue polling even on error
        attempts++;
      }
    }

    if (attempts >= maxAttempts && mounted) {
      _showTimeoutDialog();
    }
  }

  Future<void> _showPaymentInstructionsDialog(String orderNumber) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.phone_android,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            const Text('Check Your Phone'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A payment request has been sent to your ${_selectedMethod == 'mesomb_mtn' ? 'MTN' : 'Orange'} Mobile Money account.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInstruction('1', 'Check your phone for the payment prompt'),
                  _buildInstruction('2', 'Enter your PIN to confirm'),
                  _buildInstruction('3', 'Wait for confirmation'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Order Number: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Waiting for payment confirmation...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    Navigator.pop(context); // Close instructions dialog

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Payment Successful!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your payment has been confirmed.'),
            SizedBox(height: 8),
            Text('The seller will contact you soon.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.go('/'); // Go to home
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog() {
    Navigator.pop(context); // Close instructions dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Payment Failed'),
          ],
        ),
        content: const Text(
          'Your payment could not be processed. Please check your balance and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog() {
    Navigator.pop(context); // Close instructions dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Payment Timeout'),
          ],
        ),
        content: const Text(
          'Payment request timed out. Please check your order status or try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              context.go('/profile/orders');
            },
            child: const Text('View Orders'),
          ),
        ],
      ),
    );
  }

  String _formatPhoneNumber(String phone) {
    // Remove spaces and special characters
    phone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Add +237 if not present (Cameroon country code)
    if (!phone.startsWith('237')) {
      phone = '237$phone';
    }

    if (!phone.startsWith('+')) {
      phone = '+$phone';
    }

    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: productAsync.when(
        data: (product) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (product.images.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.images.first.url, // Extract the string URL from the model
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  // Good practice: Add an error builder in case the URL is broken
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat.currency(
                                      symbol: product.price.currency,
                                      decimalDigits: 0,
                                    ).format(product.price.amount),
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'Product Price',
                          NumberFormat.currency(
                            symbol: product.price.currency,
                            decimalDigits: 0,
                          ).format(product.price.amount),
                        ),
                        _buildSummaryRow(
                          'Platform Fee (${(AppConfig.commissionRate * 100).toInt()}%)',
                          NumberFormat.currency(
                            symbol: product.price.currency,
                            decimalDigits: 0,
                          ).format(product.price.amount * AppConfig.commissionRate),
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'Total Amount',
                          NumberFormat.currency(
                            symbol: product.price.currency,
                            decimalDigits: 0,
                          ).format(product.price.amount),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method Selection
                Text(
                  'Select Payment Method',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildPaymentMethodCard(
                  'mesomb_mtn',
                  'MTN Mobile Money',
                  'Pay with MTN MOMO',
                  Colors.yellow[700]!,
                ),
                const SizedBox(height: 12),
                _buildPaymentMethodCard(
                  'mesomb_orange',
                  'Orange Money',
                  'Pay with Orange Money',
                  Colors.orange,
                ),

                const SizedBox(height: 24),

                // Phone Number Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Money Number',
                    hintText: '6XX XXX XXX',
                    prefixIcon: Icon(Icons.phone),
                    prefixText: '+237 ',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length != 9) {
                      return 'Phone number must be 9 digits';
                    }
                    if (!value.startsWith('6')) {
                      return 'Invalid Cameroon number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Pay Button
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : Text(
                    'Pay ${NumberFormat.currency(
                      symbol: product.price.currency,
                      decimalDigits: 0,
                    ).format(product.price.amount)}',
                  ),
                ),

                const SizedBox(height: 16),

                // Security Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment is secure and encrypted',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading product: $error'),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
      String value,
      String title,
      String subtitle,
      Color color,
      ) {
    final isSelected = _selectedMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.phone_android, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedMethod,
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}