// ============================================================================
// SAVED SEARCHES PAGE
// lib/features/profile/presentation/pages/saved_searches_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/widgets/error_widget.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/account_repository.dart';
import '../../../../core/services/feature_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class SavedSearchesPage extends ConsumerWidget {
  const SavedSearchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchesAsync = ref.watch(savedSearchesProvider(null));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Saved Searches'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
        centerTitle: true,
      ),
      body: searchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => CustomErrorWidget(error: e),
        data: (searches) {
          if (searches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      boxShadow: AppSpacing.cardShadow,
                    ),
                    child: const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('No saved searches yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Save a search from the Jobs or Marketplace page', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: searches.length,
            itemBuilder: (context, index) {
              final s = searches[index];
              final isJob = s['searchType'] == 'job';
              final criteria = s['criteria'] ?? {};

              return Dismissible(
                key: Key(s['_id'] ?? index.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.xl),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: AppSpacing.roundedLg,
                  ),
                  child: const Icon(Icons.delete_rounded, color: AppColors.white),
                ),
                onDismissed: (_) async {
                  try {
                    await ref.read(accountRepositoryProvider).deleteSavedSearch(s['_id']);
                    ref.invalidate(savedSearchesProvider(null));
                  } catch (_) {}
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: AppSpacing.roundedLg,
                    boxShadow: AppSpacing.cardShadow,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isJob ? AppColors.primary.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      child: Icon(isJob ? Icons.work_rounded : Icons.store_rounded, color: isJob ? AppColors.primary : AppColors.success),
                    ),
                    title: Text(s['name'] ?? 'Untitled Search', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        [
                          if (criteria['query'] != null) '"${criteria['query']}"',
                          if (criteria['location'] != null) criteria['location'],
                          if (criteria['category'] != null) criteria['category'],
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          s['alertsEnabled'] == true ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                          size: 20,
                          color: s['alertsEnabled'] == true ? AppColors.accent : AppColors.textMutedLight,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isJob ? 'Job' : 'Product', 
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: AppColors.textMutedLight)
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
