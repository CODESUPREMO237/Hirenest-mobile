// Company Provider
// lib/features/company/presentation/providers/company_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/models/company_model.dart';

// My Company Provider
final myCompanyProvider = FutureProvider<CompanyModel>((ref) async {
  final repository = ref.read(companyRepositoryProvider);
  return await repository.getMyCompany();
});

// Company by ID Provider
final companyProvider = FutureProvider.family<CompanyModel, String>((ref, id) async {
  final repository = ref.read(companyRepositoryProvider);
  return await repository.getCompany(id);
});

// All Companies Provider with Pagination
final companiesProvider = FutureProvider<List<CompanyModel>>((ref) async {
  final repository = ref.read(companyRepositoryProvider);
  return await repository.getAllCompanies();
});