// lib/features/talent/presentation/providers/talent_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/talent_repository.dart';
import '../../../auth/data/models/user_model.dart';

final talentListProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.read(talentRepositoryProvider);
  return repository.getTalent();
});
