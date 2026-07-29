import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/order_details_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailsProvider(widget.orderId));
    final currentUser = ref.watch(profileProvider).value;

    if (state.isLoading && state.order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(state.error!, style: const TextStyle(color: AppColors.error)),
              ElevatedButton(
                onPressed: () => ref.read(orderDetailsProvider(widget.orderId).notifier).loadOrder(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final order = state.order!;
    final isBuyer = currentUser?.id == order.buyer?.id;
    final formatter = NumberFormat.currency(symbol: order.product?.price?.currency ?? 'FCFA', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.id.substring(order.id.length - 8).toUpperCase()}'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderDetailsProvider(widget.orderId).notifier).loadOrder(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                color: _getStatusColor(order.status).withValues(alpha: 0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: _getStatusColor(order.status).withValues(alpha: 0.3)),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusLabel(order.status),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(order.status, isBuyer),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Product Info
              const Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (order.product?.images != null && order.product!.images!.isNotEmpty)
                        ClipRRect(
                          borderRadius: AppSpacing.roundedSm,
                          child: Image.network(
                            order.product!.images!.first.url,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: AppSpacing.roundedSm),
                          child: const Icon(Icons.image, color: AppColors.textMutedLight),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.product?.name ?? 'Unknown Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(formatter.format(order.amount), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Other Party Info
              Text(isBuyer ? 'Seller Details' : 'Buyer Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (isBuyer ? order.seller?.avatar : order.buyer?.avatar) != null
                        ? NetworkImage(isBuyer ? order.seller!.avatar! : order.buyer!.avatar!)
                        : null,
                    child: (isBuyer ? order.seller?.avatar : order.buyer?.avatar) == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(isBuyer ? (order.seller?.name ?? 'Seller') : (order.buyer?.name ?? 'Buyer')),
                  subtitle: Text(isBuyer ? (order.seller?.email ?? '') : (order.buyer?.email ?? '')),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              if (isBuyer) _buildBuyerActions(context, state) else _buildSellerActions(context, state),
              
              if (state.isLoading && state.order != null)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuyerActions(BuildContext context, OrderDetailsState state) {
    final order = state.order!;
    final notifier = ref.read(orderDetailsProvider(widget.orderId).notifier);

    if (order.status == 'PAID_ESCROW' || order.status == 'SHIPPED') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nudge Seller Button — only when waiting for shipment
          if (order.status == 'PAID_ESCROW') ...[
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : () async {
                final message = await notifier.nudgeSeller();
                if (mounted && message != null) {
                  _showSuccess(message);
                } else if (mounted && state.error != null) {
                  _showError(state.error!);
                }
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Notify Seller to Ship'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: () async {
              await notifier.generateOtp();
              if (!context.mounted) return;
              if (state.error == null) {
                _showOtpModal(context);
              } else if (state.error != null) {
                _showError(state.error!);
              }
            },
            icon: const Icon(Icons.qr_code),
            label: const Text('Get Delivery Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showVerifyModal(context),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Confirm I Received This'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
            ),
          ),
          if (order.status == 'SHIPPED') ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _showRejectModal(context),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject Delivery'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ]
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSellerActions(BuildContext context, OrderDetailsState state) {
    final order = state.order!;
    final notifier = ref.read(orderDetailsProvider(widget.orderId).notifier);

    if (order.status == 'PAID_ESCROW') {
      return ElevatedButton.icon(
        onPressed: () async {
          final success = await notifier.markAsShipped();
          if (success) {
            _showSuccess('Order marked as shipped!');
          } else if (state.error != null) {
            _showError(state.error!);
          }
        },
        icon: const Icon(Icons.local_shipping),
        label: const Text('Mark as Shipped'),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      );
    }
    return const SizedBox.shrink();
  }

  void _showOtpModal(BuildContext context) {
    bool hasCopied = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(orderDetailsProvider(widget.orderId));
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Your Delivery Code',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                state.otpCode ?? '...',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 8,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (state.otpCode != null && state.otpCode!.isNotEmpty)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasCopied)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        'Copied!',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: hasCopied 
                                          ? AppColors.success.withValues(alpha: 0.1) 
                                          : AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      iconSize: 24,
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: state.otpCode!));
                                        setModalState(() {
                                          hasCopied = true;
                                        });
                                        // Reset the 'copied' state after 2 seconds
                                        Future.delayed(const Duration(seconds: 2), () {
                                          if (mounted) {
                                            setModalState(() {
                                              hasCopied = false;
                                            });
                                          }
                                        });
                                      },
                                      icon: Icon(
                                        hasCopied ? Icons.check : Icons.copy, 
                                        color: hasCopied ? AppColors.success : AppColors.primary
                                      ),
                                      tooltip: 'Copy Code',
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.roundedMd,
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Confirm this only after you've checked the item — this releases payment to the seller.",
                            style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            );
          });
          },
        );
      },
    );
  }

  void _showVerifyModal(BuildContext context) {
    _otpController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirm Delivery',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the delivery code you saw earlier to confirm you have received and inspected the item.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '000000',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_otpController.text.length != 6) return;
                    Navigator.pop(context); // Close modal
                    final success = await ref.read(orderDetailsProvider(widget.orderId).notifier).verifyOtp(_otpController.text);
                    if (success) {
                      _showSuccess('Delivery confirmed! Funds released to seller.');
                    } else {
                      final error = ref.read(orderDetailsProvider(widget.orderId)).error;
                      if (error != null) _showError(error);
                    }
                  },
                  child: const Text('Confirm & Release Funds'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showRejectModal(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Delivery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you rejecting this delivery? The order will be placed in dispute.'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Item is damaged, not as described, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.white),
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;
                Navigator.pop(context);
                final success = await ref.read(orderDetailsProvider(widget.orderId).notifier).rejectDelivery(reasonController.text.trim());
                if (success) {
                  _showSuccess('Delivery rejected. Order is now disputed.');
                } else {
                  final error = ref.read(orderDetailsProvider(widget.orderId)).error;
                  if (error != null) _showError(error);
                }
              },
              child: const Text('Reject & Dispute'),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return AppColors.warning;
      case 'PAID_ESCROW': return AppColors.primaryDark;
      case 'SHIPPED': return AppColors.primary;
      case 'OUT_FOR_DELIVERY': return AppColors.primary;
      case 'DELIVERED_CONFIRMED':
      case 'RELEASED':
      case 'AUTO_RELEASED': return AppColors.success;
      case 'DISPUTED': return AppColors.error;
      case 'REFUNDED': return AppColors.textSecondaryLight;
      default: return AppColors.textMutedLight;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING': return Icons.pending_actions;
      case 'PAID_ESCROW': return Icons.lock_outline;
      case 'SHIPPED': return Icons.local_shipping_outlined;
      case 'OUT_FOR_DELIVERY': return Icons.directions_bike;
      case 'DELIVERED_CONFIRMED':
      case 'RELEASED':
      case 'AUTO_RELEASED': return Icons.check_circle_outline;
      case 'DISPUTED': return Icons.gavel;
      case 'REFUNDED': return Icons.replay;
      default: return Icons.info_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING': return 'Pending';
      case 'PAID_ESCROW': return 'Payment Secured';
      case 'SHIPPED': return 'Shipped';
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'DELIVERED_CONFIRMED':
      case 'RELEASED':
      case 'AUTO_RELEASED': return 'Completed';
      case 'DISPUTED': return 'Disputed';
      case 'REFUNDED': return 'Refunded';
      default: return status;
    }
  }

  String _getStatusDescription(String status, bool isBuyer) {
    switch (status) {
      case 'PAID_ESCROW':
        return isBuyer
            ? 'Your payment is held securely. Awaiting shipment from the seller.'
            : 'Payment is secured. Please ship the item to the buyer.';
      case 'SHIPPED':
        return isBuyer
            ? 'The seller has shipped the item. Inspect it when it arrives, then confirm delivery.'
            : 'You have shipped the item. Awaiting buyer confirmation.';
      case 'RELEASED':
      case 'AUTO_RELEASED':
      case 'DELIVERED_CONFIRMED':
        return isBuyer
            ? 'Delivery confirmed. Funds have been released to the seller.'
            : 'Delivery confirmed! Funds have been released to your account.';
      case 'DISPUTED':
        return 'There is a dispute on this order. Our admin team will review it.';
      default:
        return '';
    }
  }
}
