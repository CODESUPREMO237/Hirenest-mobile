// lib/features/jobs/presentation/pages/jobs_page.dart

import 'package:flutter/material.dart';
import '../../../../core/widgets/error_widget.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/account_repository.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/custom_empty_state.dart';
import '../providers/jobs_provider.dart';
import '../widgets/job_card.dart';
import '../widgets/job_filter_sheet.dart';

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsProvider.notifier).loadJobs(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(jobsProvider.notifier).loadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);
    final isLoading = ref.watch(jobsPaginationLoadingProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Browse Jobs', style: AppTextStyles.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: AppColors.textPrimaryLight),
            tooltip: 'Save Search',
            onPressed: () => _showSaveSearchDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticky search bar at top with filter icon button
          Container(
            color: AppColors.surfaceLight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      hintStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(color: AppColors.textMutedLight),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMutedLight),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.roundedLg,
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMutedLight),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(jobsProvider.notifier).search('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      ref.read(jobsProvider.notifier).search(value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppSpacing.roundedLg,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: AppColors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => JobFilterSheet(
                          onApply: (filters) {
                            ref.read(jobsProvider.notifier).updateFilters(filters);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Horizontal scrolling filter chips below search
          Container(
            color: AppColors.surfaceLight,
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  _buildQuickFilterChip('Remote'),
                  _buildQuickFilterChip('Full-Time'),
                  _buildQuickFilterChip('Entry Level'),
                  _buildQuickFilterChip('Senior'),
                ],
              ),
            ),
          ),
          
          // Clean job list with shimmer loading
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(jobsProvider.notifier).loadJobs(refresh: true);
              },
              color: AppColors.primary,
              child: jobsAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return const CustomEmptyState(
                      icon: Icons.work_outline,
                      title: 'No jobs found',
                      message: 'Try adjusting your filters or search',
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: jobs.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == jobs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: ShimmerLoading(width: double.infinity, height: 160),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: JobCard(
                          job: jobs[index],
                          onTap: () => context.push('/jobs/${jobs[index].id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: 5,
                  itemBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: ShimmerLoading(width: double.infinity, height: 160),
                  ),
                ),
                error: (error, stack) => CustomErrorWidget(error: error, onRetry: () => ref.read(jobsProvider.notifier).loadJobs(refresh: true)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: ActionChip(
        label: Text(label, style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
        backgroundColor: AppColors.backgroundLight,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedFull),
        onPressed: () {},
      ),
    );
  }

  Future<void> _showSaveSearchDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    bool alertsEnabled = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
              backgroundColor: AppColors.surfaceLight,
              title: Text('Save Job Search', style: AppTextStyles.textTheme.titleLarge),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Search Name',
                      hintText: 'e.g., Remote Flutter Jobs',
                      border: OutlineInputBorder(borderRadius: AppSpacing.roundedMd),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    title: Text('Email Alerts', style: AppTextStyles.textTheme.bodyLarge ?? const TextStyle()),
                    subtitle: Text('Get notified of new matches', style: AppTextStyles.textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight)),
                    value: alertsEnabled,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => alertsEnabled = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textMutedLight)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    
                    try {
                      final repo = ref.read(accountRepositoryProvider);
                      await repo.saveSearch(
                        searchType: 'job',
                        name: nameController.text.trim(),
                        criteria: {
                          'query': _searchController.text,
                        },
                        alertsEnabled: alertsEnabled,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Search saved!'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                  ),
                  child: const Text('Save', style: TextStyle(color: AppColors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}