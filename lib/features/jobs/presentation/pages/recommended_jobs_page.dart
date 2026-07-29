import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/feature_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class RecommendedJobsPage extends ConsumerWidget {
  const RecommendedJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(recommendedJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Recommended For You'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: recAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (recommendations) {
          if (recommendations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work_outline, size: 64, color: AppColors.textMutedLight),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No recommendations yet', style: TextStyle(fontSize: 18, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: AppSpacing.xs),
                  const Text('Complete your profile to get matched!', style: TextStyle(color: AppColors.textMutedLight)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              final job = rec['job'];
              final score = rec['matchScore'] ?? 0;

              if (job == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppSpacing.roundedLg,
                  boxShadow: AppSpacing.cardShadow,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final jobId = job['_id']?.toString();
                      if (jobId != null) context.push('/jobs/$jobId');
                    },
                    borderRadius: AppSpacing.roundedLg,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  job['title'] ?? 'Untitled Job',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimaryLight,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _scoreColor(score).withValues(alpha: 0.1),
                                  borderRadius: AppSpacing.roundedFull,
                                  border: Border.all(color: _scoreColor(score).withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  '$score% match',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _scoreColor(score),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (job['postedBy']?['employerProfile']?['company'] != null ||
                              job['postedBy']?['profile']?['displayName'] != null)
                            Text(
                              job['postedBy']?['profile']?['displayName'] ?? 'Company',
                              style: const TextStyle(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              if (job['location'] != null) ...[
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMutedLight),
                                const SizedBox(width: 4),
                                Text(
                                  job['location'] is Map
                                      ? job['location']['city'] ?? ''
                                      : job['location'].toString(),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                ),
                                const SizedBox(width: AppSpacing.md),
                              ],
                              if (job['jobType'] != null) ...[
                                const Icon(Icons.schedule_outlined, size: 16, color: AppColors.textMutedLight),
                                const SizedBox(width: 4),
                                Text(job['jobType'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                              ],
                            ],
                          ),
                          if (job['isBoosted'] == true) ...[
                            const SizedBox(height: AppSpacing.md),
                            Row(children: [
                              const Icon(Icons.rocket_launch, size: 14, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text('Boosted', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.bold)),
                            ]),
                          ],
                        ],
                      ),
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

  Color _scoreColor(int score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.textSecondaryLight;
  }
}
