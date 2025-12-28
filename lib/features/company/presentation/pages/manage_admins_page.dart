// // lib/features/company/presentation/pages/manage_admins_page.dart
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/company_provider.dart';
// import '../providers/admin_provider.dart';
//
// class ManageAdminsPage extends ConsumerStatefulWidget {
//   const ManageAdminsPage({super.key});
//
//   @override
//   ConsumerState<ManageAdminsPage> createState() => _ManageAdminsPageState();
// }
//
// class _ManageAdminsPageState extends ConsumerState<ManageAdminsPage> {
//   final _searchController = TextEditingController();
//   bool _isSearching = false;
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   void _searchUsers() async {
//     if (_searchController.text.trim().isEmpty) return;
//
//     setState(() => _isSearching = true);
//
//     try {
//       await ref
//           .read(searchUsersProvider(_searchController.text.trim()).future);
//     } finally {
//       setState(() => _isSearching = false);
//     }
//   }
//
//   void _addAdmin(String userId, String companyId) async {
//     try {
//       await ref.read(adminActionsProvider.notifier).addAdmin(companyId, userId);
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Admin added successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         _searchController.clear();
//         ref.invalidate(searchUsersProvider(_searchController.text));
//         ref.invalidate(myCompanyProvider);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to add admin: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   void _removeAdmin(String adminId, String companyId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Remove Admin'),
//         content: const Text('Are you sure you want to remove this admin?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: const Text('Remove'),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed != true) return;
//
//     try {
//       await ref
//           .read(adminActionsProvider.notifier)
//           .removeAdmin(companyId, adminId);
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Admin removed successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         ref.invalidate(myCompanyProvider);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to remove admin: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final companyAsync = ref.watch(myCompanyProvider);
//     final adminState = ref.watch(adminActionsProvider);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manage Admins'),
//         elevation: 0,
//       ),
//       body: companyAsync.when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, stack) => Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, size: 64, color: Colors.red),
//               const SizedBox(height: 16),
//               Text('Error: $error'),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () => ref.invalidate(myCompanyProvider),
//                 child: const Text('Retry'),
//               ),
//             ],
//           ),
//         ),
//         data: (company) {
//           final isCreator = company.createdBy == 'current-user-id'; // Replace with actual user ID check
//
//           return RefreshIndicator(
//             onRefresh: () async {
//               ref.invalidate(myCompanyProvider);
//             },
//             child: SingleChildScrollView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade50,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           Icons.shield,
//                           color: Colors.blue.shade700,
//                           size: 32,
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Manage Admins',
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               'Add or remove administrators for ${company.name}',
//                               style: TextStyle(
//                                 color: Colors.grey.shade600,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Add Admin Section (Creator only)
//                   if (isCreator) ...[
//                     Card(
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         side: BorderSide(color: Colors.grey.shade200),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(20),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Icon(Icons.person_add,
//                                     color: Colors.blue.shade700),
//                                 const SizedBox(width: 8),
//                                 const Text(
//                                   'Add New Admin',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: TextField(
//                                     controller: _searchController,
//                                     decoration: InputDecoration(
//                                       hintText: 'Enter employer email...',
//                                       prefixIcon: const Icon(Icons.email),
//                                       border: OutlineInputBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       contentPadding: const EdgeInsets.symmetric(
//                                         horizontal: 16,
//                                         vertical: 12,
//                                       ),
//                                     ),
//                                     onSubmitted: (_) => _searchUsers(),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 ElevatedButton.icon(
//                                   onPressed:
//                                   _isSearching ? null : _searchUsers,
//                                   icon: _isSearching
//                                       ? const SizedBox(
//                                     width: 16,
//                                     height: 16,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2,
//                                       valueColor:
//                                       AlwaysStoppedAnimation<Color>(
//                                           Colors.white),
//                                     ),
//                                   )
//                                       : const Icon(Icons.search),
//                                   label: const Text('Search'),
//                                   style: ElevatedButton.styleFrom(
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 24,
//                                       vertical: 16,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             // Search Results
//                             Consumer(
//                               builder: (context, ref, child) {
//                                 final searchAsync = ref.watch(
//                                   searchUsersProvider(
//                                       _searchController.text.trim()),
//                                 );
//
//                                 return searchAsync.when(
//                                   data: (users) {
//                                     if (users.isEmpty) return const SizedBox();
//
//                                     return Column(
//                                       children: users
//                                           .map((user) => Container(
//                                         margin: const EdgeInsets.only(
//                                             bottom: 8),
//                                         padding:
//                                         const EdgeInsets.all(12),
//                                         decoration: BoxDecoration(
//                                           color: Colors.grey.shade50,
//                                           borderRadius:
//                                           BorderRadius.circular(8),
//                                         ),
//                                         child: Row(
//                                           children: [
//                                             CircleAvatar(
//                                               backgroundColor:
//                                               Colors.blue.shade100,
//                                               child: Icon(Icons.person,
//                                                   color: Colors
//                                                       .blue.shade700),
//                                             ),
//                                             const SizedBox(width: 12),
//                                             Expanded(
//                                               child: Column(
//                                                 crossAxisAlignment:
//                                                 CrossAxisAlignment
//                                                     .start,
//                                                 children: [
//                                                   Text(
//                                                     '${user.firstName} ${user.lastName}',
//                                                     style:
//                                                     const TextStyle(
//                                                       fontWeight:
//                                                       FontWeight
//                                                           .bold,
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     user.email,
//                                                     style: TextStyle(
//                                                       fontSize: 12,
//                                                       color: Colors
//                                                           .grey.shade600,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             ElevatedButton(
//                                               onPressed: () => _addAdmin(
//                                                   user.id, company.id),
//                                               style: ElevatedButton
//                                                   .styleFrom(
//                                                 padding:
//                                                 const EdgeInsets
//                                                     .symmetric(
//                                                   horizontal: 16,
//                                                   vertical: 8,
//                                                 ),
//                                               ),
//                                               child: const Text(
//                                                   'Add as Admin'),
//                                             ),
//                                           ],
//                                         ),
//                                       ))
//                                           .toList(),
//                                     );
//                                   },
//                                   loading: () => const SizedBox(),
//                                   error: (_, __) => const SizedBox(),
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                   ],
//
//                   // Current Admins List
//                   Card(
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       side: BorderSide(color: Colors.grey.shade200),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Current Admins (${company.admins.length})',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           if (company.admins.isEmpty)
//                             Center(
//                               child: Padding(
//                                 padding: const EdgeInsets.all(32),
//                                 child: Column(
//                                   children: [
//                                     Icon(Icons.people_outline,
//                                         size: 64, color: Colors.grey.shade400),
//                                     const SizedBox(height: 16),
//                                     Text(
//                                       'No admins yet',
//                                       style: TextStyle(
//                                         color: Colors.grey.shade600,
//                                         fontSize: 16,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             )
//                           else
//                             ...company.admins.map((adminId) {
//                               final isAdminCreator = adminId == company.createdBy;
//                               final isRemoving = adminState.isLoading &&
//                                   adminState.currentAdminId == adminId;
//
//                               return Container(
//                                 margin: const EdgeInsets.only(bottom: 12),
//                                 padding: const EdgeInsets.all(16),
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey.shade50,
//                                   borderRadius: BorderRadius.circular(8),
//                                   border: Border.all(
//                                     color: isAdminCreator
//                                         ? Colors.amber.shade200
//                                         : Colors.transparent,
//                                   ),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Container(
//                                       width: 48,
//                                       height: 48,
//                                       decoration: BoxDecoration(
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             Colors.blue.shade400,
//                                             Colors.purple.shade600,
//                                           ],
//                                         ),
//                                         borderRadius: BorderRadius.circular(24),
//                                       ),
//                                       child: const Icon(
//                                         Icons.person,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                     const SizedBox(width: 16),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Text(
//                                                 'Admin ${adminId.substring(0, 8)}...',
//                                                 style: const TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 16,
//                                                 ),
//                                               ),
//                                               if (isAdminCreator) ...[
//                                                 const SizedBox(width: 8),
//                                                 Container(
//                                                   padding:
//                                                   const EdgeInsets.symmetric(
//                                                     horizontal: 8,
//                                                     vertical: 4,
//                                                   ),
//                                                   decoration: BoxDecoration(
//                                                     color:
//                                                     Colors.amber.shade100,
//                                                     borderRadius:
//                                                     BorderRadius.circular(
//                                                         12),
//                                                   ),
//                                                   child: Row(
//                                                     mainAxisSize:
//                                                     MainAxisSize.min,
//                                                     children: [
//                                                       Icon(
//                                                         Icons.shield,
//                                                         size: 12,
//                                                         color: Colors
//                                                             .amber.shade900,
//                                                       ),
//                                                       const SizedBox(width: 4),
//                                                       Text(
//                                                         'Creator',
//                                                         style: TextStyle(
//                                                           fontSize: 10,
//                                                           fontWeight:
//                                                           FontWeight.bold,
//                                                           color: Colors
//                                                               .amber.shade900,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ],
//                                             ],
//                                           ),
//                                           const SizedBox(height: 4),
//                                           Row(
//                                             children: [
//                                               Icon(
//                                                 Icons.email,
//                                                 size: 14,
//                                                 color: Colors.grey.shade600,
//                                               ),
//                                               const SizedBox(width: 4),
//                                               Text(
//                                                 'admin@example.com',
//                                                 style: TextStyle(
//                                                   fontSize: 12,
//                                                   color: Colors.grey.shade600,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     if (isCreator && !isAdminCreator)
//                                       isRemoving
//                                           ? const SizedBox(
//                                         width: 24,
//                                         height: 24,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                         ),
//                                       )
//                                           : IconButton(
//                                         onPressed: () =>
//                                             _removeAdmin(adminId, company.id),
//                                         icon: const Icon(Icons.delete),
//                                         color: Colors.red.shade600,
//                                         tooltip: 'Remove admin',
//                                       ),
//                                   ],
//                                 ),
//                               );
//                             }),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Info Box
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.blue.shade200),
//                     ),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Icon(Icons.info_outline, color: Colors.blue.shade700),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'About Admin Permissions',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.blue.shade900,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 '• Admins can update company profile and manage job postings\n'
//                                     '• Only the creator can add or remove other admins\n'
//                                     '• The creator cannot be removed from admin list\n'
//                                     '• New admins must have an employer account',
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   color: Colors.blue.shade800,
//                                   height: 1.5,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }