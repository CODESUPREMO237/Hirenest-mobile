// // lib/features/company/presentation/providers/admin_provider.dart
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../auth/data/models/user_model.dart';
// import '../../data/repositories/company_repository.dart';
//
//
// // Admin Actions State
// class AdminActionsState {
//   final bool isLoading;
//   final String? error;
//   final String? currentAdminId;
//
//   AdminActionsState({
//     this.isLoading = false,
//     this.error,
//     this.currentAdminId,
//   });
//
//   AdminActionsState copyWith({
//     bool? isLoading,
//     String? error,
//     String? currentAdminId,
//   }) {
//     return AdminActionsState(
//       isLoading: isLoading ?? this.isLoading,
//       error: error ?? this.error,
//       currentAdminId: currentAdminId ?? this.currentAdminId,
//     );
//   }
// }
//
// // Admin Actions Notifier
// class AdminActionsNotifier extends StateNotifier<AdminActionsState> {
//   final CompanyRepository _repository;
//
//   AdminActionsNotifier(this._repository) : super(AdminActionsState());
//
//   Future<void> addAdmin(String companyId, String userId) async {
//     state = state.copyWith(isLoading: true, error: null);
//
//     try {
//       await _repository.addAdmin(companyId, userId);
//       state = state.copyWith(isLoading: false);
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: e.toString(),
//       );
//       rethrow;
//     }
//   }
//
//   Future<void> removeAdmin(String companyId, String adminId) async {
//     state = state.copyWith(
//       isLoading: true,
//       error: null,
//       currentAdminId: adminId,
//     );
//
//     try {
//       await _repository.removeAdmin(companyId, adminId);
//       state = state.copyWith(isLoading: false, currentAdminId: null);
//     } catch (e) {
//       state = state.copyWith(
//         isLoading: false,
//         error: e.toString(),
//         currentAdminId: null,
//       );
//       rethrow;
//     }
//   }
// }
//
// // Admin Actions Provider
// final adminActionsProvider =
// StateNotifierProvider<AdminActionsNotifier, AdminActionsState>((ref) {
//   return AdminActionsNotifier(ref.read(companyRepositoryProvider));
// });
//
// // Search Users Provider
// final searchUsersProvider =
// FutureProvider.family<List<UserModel>, String>((ref, email) async {
//   if (email.isEmpty) return [];
//
//   final repository = ref.read(companyRepositoryProvider);
//   return await repository.searchUsers(email);
// });