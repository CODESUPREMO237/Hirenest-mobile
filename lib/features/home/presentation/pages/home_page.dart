// lib/features/home/presentation/pages/home_page_simple.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../marketplace/presentation/providers/PaginatedProductsNotifier.dart';
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
      AppLogger.debug('Getting display name for user: ${user.email}');
      AppLogger.debug('Profile data: firstName=${user.profile?.firstName}, lastName=${user.profile?.lastName}, displayName=${user.profile?.displayName}');

      // Use the computed displayName from UserModel
      return user.displayName;
    } catch (e, stack) {
      AppLogger.error('Error getting display name', error: e, stackTrace: stack);
      return user.email.split('@')[0];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.info('Building HomePageSimple');

    final productsState = ref.watch(paginatedProductsProvider);
    final jobsState = ref.watch(featuredJobsProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.work_outline,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JobConnect',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Marketplace',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.push('/profile/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          AppLogger.info('Refreshing home page data');
          await ref.read(paginatedProductsProvider.notifier).refresh();
          ref.invalidate(featuredJobsProvider);
        },
        child: userAsync.when(
          data: (user) => _buildContent(context, ref, user, productsState, jobsState),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            AppLogger.error('Error loading user data', error: error, stackTrace: stack);
            return CustomErrorWidget(
              message: 'Failed to load user data: ${error.toString()}',
              onRetry: () {
                ref.invalidate(currentUserProvider);
              },
            );
          },
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
        // Welcome Section
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user != null
                      ? 'Welcome back, ${_getDisplayName(user)}! 👋'
                      : 'Welcome! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find your next opportunity or sell products',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Quick Actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.add_shopping_cart,
                        title: 'Sell Product',
                        color: Colors.orange,
                        onTap: () {
                          AppLogger.debug('Quick action: Sell Product tapped');
                          ref.read(selectedIndexProvider.notifier).state = 1;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.work_outline,
                        title: 'Find Jobs',
                        color: Colors.blue,
                        onTap: () {
                          AppLogger.debug('Quick action: Find Jobs tapped');
                          ref.read(selectedIndexProvider.notifier).state = 2;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Recent Products Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppLogger.debug('See All Products tapped');
                    ref.read(selectedIndexProvider.notifier).state = 1;
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
        ),

        // Products Grid
        productsState.when(
          data: (state) {
            AppLogger.debug('Products loaded: ${state.products.length} products');

            if (state.products.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No products available yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final displayProducts = state.products.take(4).toList();

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final product = displayProducts[index];
                    return _ProductCard(
                      product: product,
                      onTap: () {
                        AppLogger.debug('Product tapped: ${product.id}');
                        context.push('/marketplace/products/${product.id}');
                      },
                    );
                  },
                  childCount: displayProducts.length,
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) {
            AppLogger.error('Error loading products', error: error, stackTrace: stack);
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomErrorWidget(
                  message: 'Failed to load products',
                  onRetry: () {
                    AppLogger.info('Retrying products load');
                    ref.read(paginatedProductsProvider.notifier).refresh();
                  },
                ),
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Featured Jobs Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Jobs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppLogger.debug('See All Jobs tapped');
                    ref.read(selectedIndexProvider.notifier).state = 2;
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
        ),

        // Featured Jobs List
        jobsState.when(
          data: (jobs) {
            AppLogger.debug('Jobs loaded: ${jobs.length} jobs');

            if (jobs.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.work_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No jobs available yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              );
            }

            final displayJobs = jobs.take(3).toList();

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final job = displayJobs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _JobCard(
                        job: job,
                        onTap: () {
                          AppLogger.debug('Job tapped: ${job.id}');
                          context.push('/jobs/${job.id}');
                        },
                      ),
                    );
                  },
                  childCount: displayJobs.length,
                ),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) {
            AppLogger.error('Error loading jobs', error: error, stackTrace: stack);
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomErrorWidget(
                  message: 'Failed to load jobs',
                  onRetry: () {
                    AppLogger.info('Retrying jobs load');
                    ref.invalidate(featuredJobsProvider);
                  },
                ),
              ),
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: product.images.isNotEmpty
                  ? Image.network(
                product.primaryImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  AppLogger.warn('Failed to load product image: ${product.primaryImageUrl}');
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 48, color: Colors.grey),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              )
                  : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 48, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.amount.toStringAsFixed(0)} ${product.price.currency}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.location.city,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

class _JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (job.company.logo != null && job.company.logo!.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(job.company.logo!),
                      radius: 24,
                      onBackgroundImageError: (exception, stackTrace) {
                        AppLogger.warn('Failed to load company logo: ${job.company.logo}');
                      },
                    )
                  else
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        job.company.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.company.name,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _JobChip(icon: Icons.work_outline, label: job.jobType),
                  _JobChip(
                    icon: Icons.location_on_outlined,
                    label: job.location.type == 'remote'
                        ? 'Remote'
                        : job.location.address?.city ?? 'On-site',
                  ),
                  if (job.salary != null && job.salary!.showSalary)
                    _JobChip(
                      icon: Icons.attach_money,
                      label: '${job.salary!.min?.toStringAsFixed(0) ?? ''}${job.salary!.max != null ? '-${job.salary!.max!.toStringAsFixed(0)}' : ''} ${job.salary!.currency}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _JobChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}