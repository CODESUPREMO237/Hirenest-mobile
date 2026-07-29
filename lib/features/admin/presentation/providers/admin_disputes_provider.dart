// ============================================================================
// Admin Disputes Provider
// lib/features/admin/presentation/providers/admin_disputes_provider.dart
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_service.dart';
import '../../data/repositories/admin_repository.dart';

// Reuse or define the AdminService provider
final adminServiceProvider = Provider<AdminService>((ref) {
  final dio = ref.watch(dioProvider);
  final authService = ref.watch(authServiceProvider);
  return AdminService(dio, authService);
});

// Disputed Orders Provider
final disputedOrdersProvider = FutureProvider<List<dynamic>>((ref) async {
  final adminService = ref.read(adminServiceProvider);
  final data = await adminService.getDisputedOrders();
  return data['disputedOrders'] as List<dynamic>? ?? [];
});
