// lib/features/home/presentation/pages/home_page_simple.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

import '../../../marketplace/presentation/providers/paginated_products_notifier.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../../marketplace/data/models/product_model.dart';
import '../../../jobs/data/models/job_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/logger.dart';
import './main_page.dart';

class HomePageSimple extends ConsumerWidget {
  const HomePageSimple({super.key});

  String _getDisplayName(UserModel user) {
    try {
      return user.displayName;
    } catch (e, stack) {
      AppLogger.error('Error getting display name', error: e, stackTrace: stack);
      return user.email.split('@')[0];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(paginatedProductsProvider);
    final jobsState = ref.watch(featuredJobsProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(paginatedProductsProvider.notifier).refresh();
            ref.invalidate(featuredJobsProvider);
          },
          child: userAsync.when(
            data: (user) => _buildContent(context, ref, user, productsState, jobsState),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => CustomErrorWidget(
              message: 'Failed to load user data: ${error.toString()}',
              onRetry: () => ref.invalidate(currentUserProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    AsyncValue productsState,
    AsyncValue jobsState,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeaderAndSearch(context, user),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverToBoxAdapter(
          child: _buildQuickStats(context),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'Featured Jobs', () {
            ref.read(selectedIndexProvider.notifier).state = 2;
          }),
        ),
        SliverToBoxAdapter(
          child: _buildFeaturedJobsList(context, jobsState),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'Marketplace Highlights', () {
            ref.read(selectedIndexProvider.notifier).state = 1;
          }),
        ),
        SliverToBoxAdapter(
          child: _buildMarketplaceList(context, productsState),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Recent Activity',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildRecentActivityItem(context, index),
              childCount: 3,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  Widget _buildHeaderAndSearch(BuildContext context, UserModel? user) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user != null ? 'Good Morning, ${_getDisplayName(user)}!' : 'Good Morning!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Find your next opportunity',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      context.push('/profile/notifications');
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: user?.profile?.avatar != null && user!.profile!.avatar!.isNotEmpty
                        ? NetworkImage(user.profile!.avatar!)
                        : null,
                    child: user?.profile?.avatar == null || user!.profile!.avatar!.isEmpty
                        ? Text(
                            (user != null ? _getDisplayName(user) : '?')[0].toUpperCase(),
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: () {
              // Navigate to search
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                borderRadius: AppSpacing.roundedMd,
                boxShadow: AppSpacing.cardShadow,
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textMutedLight),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Search jobs, companies, or products...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(child: _StatCard(title: 'Applied', count: '12', icon: Icons.send_rounded, color: AppColors.primary)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _StatCard(title: 'Interviews', count: '3', icon: Icons.calendar_today_rounded, color: AppColors.accent)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _StatCard(title: 'Saved', count: '24', icon: Icons.bookmark_rounded, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedJobsList(BuildContext context, AsyncValue jobsState) {
    return jobsState.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: Text('No jobs available yet')),
          );
        }
        
        final displayJobs = jobs.take(5).toList();
        
        return SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: displayJobs.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final job = displayJobs[index];
              return _CompactJobCard(
                job: job,
                onTap: () {
                  context.push('/jobs/${job.id}');
                },
              );
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 160,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, index) => const _ShimmerCard(width: 280, height: 160),
        ),
      ),
      error: (error, _) => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: Text('Error loading jobs')),
      ),
    );
  }

  Widget _buildMarketplaceList(BuildContext context, AsyncValue productsState) {
    return productsState.when(
      data: (state) {
        if (state.products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: Text('No products available yet')),
          );
        }

        final displayProducts = state.products.take(5).toList();

        return SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: displayProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final product = displayProducts[index];
              return _CompactProductCard(
                product: product,
                onTap: () {
                  context.push('/marketplace/products/${product.id}');
                },
              );
            },
          ),
        );
      },
      loading: () => SizedBox(
        height: 200,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, index) => const _ShimmerCard(width: 140, height: 200),
        ),
      ),
      error: (error, _) => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: Text('Error loading products')),
      ),
    );
  }

  Widget _buildRecentActivityItem(BuildContext context, int index) {
    final activities = [
      {'title': 'Application viewed by TechCorp', 'time': '2h ago', 'icon': Icons.remove_red_eye, 'color': AppColors.primary},
      {'title': 'New message from Recruiter', 'time': '5h ago', 'icon': Icons.chat_bubble, 'color': AppColors.accent},
      {'title': 'Your product was sold!', 'time': '1d ago', 'icon': Icons.monetization_on, 'color': AppColors.success},
    ];
    final activity = activities[index];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['time'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedMd,
        boxShadow: AppSpacing.cardShadow,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.md),
          Text(
            count,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactJobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _CompactJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: AppSpacing.roundedMd,
          boxShadow: AppSpacing.cardShadow,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (job.company.logo != null && job.company.logo!.isNotEmpty)
                  ClipRRect(
                    borderRadius: AppSpacing.roundedSm,
                    child: CachedNetworkImage(
                      imageUrl: job.company.logo!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildInitialsLogo(theme),
                    ),
                  )
                else
                  _buildInitialsLogo(theme),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        job.company.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMutedLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (job.salary != null && job.salary!.showSalary)
              Text(
                '${job.salary!.currency} ${job.salary!.min?.toStringAsFixed(0) ?? ''}${job.salary!.max != null ? ' - ${job.salary!.max!.toStringAsFixed(0)}' : ''}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    job.jobType,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textMutedLight.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    job.location.type == 'remote'
                        ? 'Remote'
                        : job.location.address?.city ?? 'On-site',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsLogo(ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Center(
        child: Text(
          job.company.name.isNotEmpty ? job.company.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CompactProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _CompactProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: AppSpacing.roundedMd,
          boxShadow: AppSpacing.cardShadow,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.primaryImageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? AppColors.borderDark : Colors.grey[200],
                          child: Icon(Icons.image, color: AppColors.textMutedLight),
                        ),
                      )
                    : Container(
                        color: isDark ? AppColors.borderDark : Colors.grey[200],
                        child: Icon(Icons.image, color: AppColors.textMutedLight),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.price.currency} ${product.price.amount.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double width;
  final double height;

  const _ShimmerCard({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: AppSpacing.roundedMd,
        ),
      ),
    );
  }
}
