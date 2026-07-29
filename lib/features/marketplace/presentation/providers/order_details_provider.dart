import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/marketplace_repository.dart';

class OrderDetailsState {
  final OrderModel? order;
  final bool isLoading;
  final String? error;
  final String? otpCode;

  OrderDetailsState({
    this.order,
    this.isLoading = false,
    this.error,
    this.otpCode,
  });

  OrderDetailsState copyWith({
    OrderModel? order,
    bool? isLoading,
    String? error,
    String? otpCode,
  }) {
    return OrderDetailsState(
      order: order ?? this.order,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpCode: otpCode ?? this.otpCode,
    );
  }
}

class OrderDetailsNotifier extends StateNotifier<OrderDetailsState> {
  final MarketplaceRepository repository;
  final String orderId;

  OrderDetailsNotifier(this.repository, this.orderId)
      : super(OrderDetailsState(isLoading: true)) {
    loadOrder();
  }

  Future<void> loadOrder() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await repository.getOrder(orderId);
      state = state.copyWith(order: order, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> generateOtp() async {
    try {
      final otp = await repository.getDeliveryOtp(orderId);
      state = state.copyWith(otpCode: otp);
    } catch (e) {
      state = state.copyWith(error: 'Failed to get delivery code: $e');
    }
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.verifyDeliveryOtp(orderId, otp);
      await loadOrder(); // Refresh order to get new status
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to confirm delivery: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> rejectDelivery(String reason) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.rejectDelivery(orderId, reason);
      await loadOrder();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to reject delivery: $e', isLoading: false);
      return false;
    }
  }

  Future<bool> markAsShipped() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.markAsShipped(orderId);
      await loadOrder();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to mark as shipped: $e', isLoading: false);
      return false;
    }
  }

  Future<String?> nudgeSeller() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final message = await repository.nudgeSeller(orderId);
      state = state.copyWith(isLoading: false);
      return message;
    } catch (e) {
      final errorMsg = e.toString().contains('429')
          ? 'Please wait before sending another reminder.'
          : 'Failed to send reminder: $e';
      state = state.copyWith(error: errorMsg, isLoading: false);
      return null;
    }
  }
}

final orderDetailsProvider = StateNotifierProvider.family<OrderDetailsNotifier, OrderDetailsState, String>((ref, orderId) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return OrderDetailsNotifier(repository, orderId);
});

// Providers for the lists (My Orders, My Sales)
final myOrdersProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.getMyOrders();
});

final mySalesProvider = FutureProvider.autoDispose<List<OrderModel>>((ref) {
  final repository = ref.watch(marketplaceRepositoryProvider);
  return repository.getMySales();
});
