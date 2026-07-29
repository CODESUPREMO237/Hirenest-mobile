// Analytics Dashboard Page with DEBUG LOGGING
// lib/features/analytics/presentation/pages/analytics_page.dart

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fl_chart/fl_chart.dart';

import '../providers/analytics_provider.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    developer.log('📊 Analytics Page Initialized', name: 'AnalyticsPage');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(userAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Jobs', icon: Icon(Icons.work_outline)),
            Tab(text: 'Marketplace', icon: Icon(Icons.shopping_bag_outlined)),
          ],
        ),
      ),
      body: analyticsAsync.when(
        data: (analytics) {
          // 🔍 DEBUG: Log the entire analytics data
          developer.log(
            '✅ Analytics Data Received',
            name: 'AnalyticsPage',
            error: analytics.toString(),
          );

          // 🔍 DEBUG: Log specific values
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('📊 ANALYTICS DEBUG OUTPUT');
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('Total Jobs: ${analytics['totalJobs']}');
          debugPrint('Active Jobs: ${analytics['activeJobs']}');
          debugPrint('Total Applications: ${analytics['totalApplications']}');
          debugPrint('Total Views: ${analytics['totalViews']}');
          debugPrint('Total Unique Views: ${analytics['totalUniqueViews']}');
          debugPrint('───────────────────────────────────────────────────────');
          debugPrint('Marketplace Data:');
          debugPrint('  Total Products: ${analytics['marketplace']?['totalProducts']}');
          debugPrint('  Active Products: ${analytics['marketplace']?['activeProducts']}');
          debugPrint('  Total Views: ${analytics['marketplace']?['totalViews']}');
          debugPrint('  Seller Rating: ${analytics['marketplace']?['sellerRating']}');
          debugPrint('───────────────────────────────────────────────────────');
          debugPrint('Jobs with Stats:');
          final jobsWithStats = analytics['jobsWithStats'] as List?;
          if (jobsWithStats != null) {
            for (var job in jobsWithStats) {
              debugPrint('  Job: ${job['title']}');
              debugPrint('    Views: ${job['views']}');
              debugPrint('    Unique Views: ${job['uniqueViews']}');
              debugPrint('    Applications: ${job['applications']}');
              debugPrint('    Status: ${job['status']}');
            }
          } else {
            debugPrint('  No jobs with stats found');
          }
          debugPrint('───────────────────────────────────────────────────────');
          debugPrint('Application Stats:');
          final appStats = analytics['applicationStats'] as List?;
          if (appStats != null) {
            for (var stat in appStats) {
              debugPrint('  ${stat['_id']}: ${stat['count']}');
            }
          }
          debugPrint('───────────────────────────────────────────────────────');
          debugPrint('Jobs by Status:');
          final jobsByStatus = analytics['jobsByStatus'] as List?;
          if (jobsByStatus != null) {
            for (var status in jobsByStatus) {
              debugPrint('  ${status['_id']}: ${status['count']}');
            }
          }
          debugPrint('═══════════════════════════════════════════════════════\n');

          return RefreshIndicator(
            onRefresh: () async {
              developer.log('🔄 Refreshing Analytics', name: 'AnalyticsPage');
              ref.invalidate(userAnalyticsProvider);
            },
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(analytics),
                _buildJobsTab(analytics),
                _buildMarketplaceTab(analytics),
              ],
            ),
          );
        },
        loading: () {
          developer.log('⏳ Loading Analytics...', name: 'AnalyticsPage');
          debugPrint('⏳ Analytics Page: Loading data...');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          developer.log(
            '❌ Analytics Error',
            name: 'AnalyticsPage',
            error: error,
            stackTrace: stack,
          );
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('❌ ANALYTICS ERROR');
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('Error: $error');
          debugPrint('Stack Trace: $stack');
          debugPrint('═══════════════════════════════════════════════════════\n');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading analytics: $error'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('🔄 Retrying analytics fetch...');
                    ref.invalidate(userAnalyticsProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> analytics) {
    developer.log('🏠 Building Overview Tab', name: 'AnalyticsPage');

    final totalJobs = analytics['totalJobs'] ?? 0;
    final totalApplications = analytics['totalApplications'] ?? 0;
    final totalProducts = analytics['marketplace']?['totalProducts'] ?? 0;
    final totalViews = analytics['totalViews'] ?? 0; // 🔍 Job views
    final marketplaceViews = analytics['marketplace']?['totalViews'] ?? 0; // 🔍 Product views

    debugPrint('📊 Overview Tab - Displaying:');
    debugPrint('  Total Jobs: $totalJobs');
    debugPrint('  Total Applications: $totalApplications');
    debugPrint('  Total Products: $totalProducts');
    debugPrint('  Job Views: $totalViews');
    debugPrint('  Marketplace Views: $marketplaceViews');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Key Metrics
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _MetricCard(
              icon: Icons.work_outline,
              title: 'Total Jobs',
              value: '$totalJobs',
              color: AppColors.primary,
              trend: '+12%',
              isPositive: true,
            ),
            _MetricCard(
              icon: Icons.people_outline,
              title: 'Applications',
              value: '$totalApplications',
              color: AppColors.success,
              trend: '+8%',
              isPositive: true,
            ),
            _MetricCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Products',
              value: '$totalProducts',
              color: AppColors.accent,
              trend: '+5%',
              isPositive: true,
            ),
            _MetricCard(
              icon: Icons.visibility_outlined,
              title: 'Job Views', // Changed to clarify this is job views
              value: '$totalViews',
              color: AppColors.warning,
              trend: '+15%',
              isPositive: true,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Activity Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildActivityChart(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Quick Stats
        Row(
          children: [
            Expanded(
              child: _QuickStatCard(
                icon: Icons.check_circle_outline,
                title: 'Active Jobs',
                value: '${analytics['activeJobs'] ?? 0}',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickStatCard(
                icon: Icons.star_outline,
                title: 'Avg Rating',
                value: '${analytics['marketplace']?['sellerRating']?['average']?.toStringAsFixed(1) ?? '0.0'}',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJobsTab(Map<String, dynamic> analytics) {
    developer.log('💼 Building Jobs Tab', name: 'AnalyticsPage');

    final applicationsByJob = analytics['applicationsByJob'] as List? ?? [];
    final totalViews = analytics['totalViews'] ?? 0;
    final totalUniqueViews = analytics['totalUniqueViews'] ?? 0;

    debugPrint('💼 Jobs Tab - Data:');
    debugPrint('  Total Views: $totalViews');
    debugPrint('  Unique Views: $totalUniqueViews');
    debugPrint('  Applications by Job: ${applicationsByJob.length} jobs');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Jobs Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jobs Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      label: 'Total Jobs',
                      value: '${analytics['totalJobs'] ?? 0}',
                      color: AppColors.primary,
                    ),
                    _StatColumn(
                      label: 'Active',
                      value: '${analytics['activeJobs'] ?? 0}',
                      color: AppColors.success,
                    ),
                    _StatColumn(
                      label: 'Applications',
                      value: '${analytics['totalApplications'] ?? 0}',
                      color: AppColors.accent,
                    ),
                  ],
                ),
                const Divider(height: 32),
                // Add Views Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      label: 'Total Views',
                      value: '$totalViews',
                      color: AppColors.warning,
                    ),
                    _StatColumn(
                      label: 'Unique Views',
                      value: '$totalUniqueViews',
                      color: AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Application Status Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Status Distribution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildApplicationStatusChart(analytics),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Applications by Job
        if (applicationsByJob.isNotEmpty) ...[
          Text(
            'Applications by Job',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...applicationsByJob.map((jobApp) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.work_outline),
              ),
              title: const Text('Job'),
              subtitle: Text('${jobApp['total']} applications'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${jobApp['pending']} pending',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    '${jobApp['shortlisted']} shortlisted',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildMarketplaceTab(Map<String, dynamic> analytics) {
    developer.log('🛒 Building Marketplace Tab', name: 'AnalyticsPage');

    final marketplace = analytics['marketplace'] as Map<String, dynamic>? ?? {};

    debugPrint('🛒 Marketplace Tab - Data:');
    debugPrint('  Total Products: ${marketplace['totalProducts']}');
    debugPrint('  Active Products: ${marketplace['activeProducts']}');
    debugPrint('  Total Views: ${marketplace['totalViews']}');
    debugPrint('  Seller Rating: ${marketplace['sellerRating']}');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Marketplace Summary
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _MetricCard(
              icon: Icons.shopping_bag_outlined,
              title: 'Total Products',
              value: '${marketplace['totalProducts'] ?? 0}',
              color: AppColors.primary,
            ),
            _MetricCard(
              icon: Icons.check_circle_outline,
              title: 'Active Products',
              value: '${marketplace['activeProducts'] ?? 0}',
              color: AppColors.success,
            ),
            _MetricCard(
              icon: Icons.visibility_outlined,
              title: 'Total Views',
              value: '${marketplace['totalViews'] ?? 0}',
              color: AppColors.accent,
            ),
            _MetricCard(
              icon: Icons.star_outline,
              title: 'Seller Rating',
              value: '${marketplace['sellerRating']?['average']?.toStringAsFixed(1) ?? '0.0'}',
              color: AppColors.accent,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Product Performance
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPerformanceMetric(
                  'Average Views per Product',
                  marketplace['totalProducts'] != null && marketplace['totalProducts'] > 0
                      ? '${(marketplace['totalViews'] / marketplace['totalProducts']).toStringAsFixed(0)}'
                      : '0',
                  AppColors.primary,
                ),
                const Divider(height: 24),
                _buildPerformanceMetric(
                  'Active Rate',
                  marketplace['totalProducts'] != null && marketplace['totalProducts'] > 0
                      ? '${((marketplace['activeProducts'] / marketplace['totalProducts']) * 100).toStringAsFixed(1)}%'
                      : '0%',
                  AppColors.success,
                ),
                const Divider(height: 24),
                _buildPerformanceMetric(
                  'Rating Count',
                  '${marketplace['sellerRating']?['count'] ?? 0}',
                  AppColors.accent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
// UNIVERSAL fl_chart Compatible Modern Activity Chart
// This works with most fl_chart versions
// Replace your _buildActivityChart() method with this

  Widget _buildActivityChart() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.shade50,
            AppColors.accent.shade50,
          ],
        ),
        borderRadius: AppSpacing.roundedLg,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _ChartLegendItem(
                color: AppColors.primary,
                label: 'Jobs',
              ),
              SizedBox(width: 24),
              _ChartLegendItem(
                color: AppColors.accent,
                label: 'Products',
              ),
              SizedBox(width: 24),
              _ChartLegendItem(
                color: AppColors.success,
                label: 'Applications',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.textMutedLight.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textMutedLight,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Mon';
                            break;
                          case 1:
                            text = 'Tue';
                            break;
                          case 2:
                            text = 'Wed';
                            break;
                          case 3:
                            text = 'Thu';
                            break;
                          case 4:
                            text = 'Fri';
                            break;
                          case 5:
                            text = 'Sat';
                            break;
                          case 6:
                            text = 'Sun';
                            break;
                          default:
                            text = '';
                        }
                        return Text(text, style: style);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: AppColors.textMutedLight,
                        );
                        return Text(
                          value.toInt().toString(),
                          style: style,
                          textAlign: TextAlign.left,
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 12,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.textSecondaryLight.withValues(alpha: 0.9),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        String label;
                        if (barSpot.barIndex == 0) {
                          label = 'Jobs';
                        } else if (barSpot.barIndex == 1) {
                          label = 'Products';
                        } else {
                          label = 'Applications';
                        }
                        return LineTooltipItem(
                          '$label\n${barSpot.y.toInt()}',
                          const TextStyle(
                            color: AppColors.surfaceLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: AppColors.surfaceLight.withValues(alpha: 0.5),
                          strokeWidth: 2,
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: AppColors.surfaceLight,
                              strokeWidth: 3,
                              strokeColor: barData.gradient?.colors.first ?? barData.color ?? AppColors.primary,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),
                lineBarsData: [
                  // Jobs Line
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 5),
                      FlSpot(2, 4),
                      FlSpot(3, 7),
                      FlSpot(4, 6),
                      FlSpot(5, 8),
                      FlSpot(6, 9),
                    ],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.shade400,
                        AppColors.primary.shade600,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.surfaceLight,
                          strokeWidth: 2,
                          strokeColor: AppColors.primary.shade600,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Products Line
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 3),
                      FlSpot(2, 5),
                      FlSpot(3, 4),
                      FlSpot(4, 6),
                      FlSpot(5, 7),
                      FlSpot(6, 8),
                    ],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.shade400,
                        AppColors.accent.shade600,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.surfaceLight,
                          strokeWidth: 2,
                          strokeColor: AppColors.accent.shade600,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.2),
                          AppColors.accent.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Applications Line
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 4),
                      FlSpot(1, 6),
                      FlSpot(2, 5),
                      FlSpot(3, 8),
                      FlSpot(4, 9),
                      FlSpot(5, 10),
                      FlSpot(6, 11),
                    ],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.shade400,
                        AppColors.success.shade600,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.surfaceLight,
                          strokeWidth: 2,
                          strokeColor: AppColors.success.shade600,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withValues(alpha: 0.2),
                          AppColors.success.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildApplicationStatusChart(Map<String, dynamic> analytics) {
    final pending = analytics['applicationStats']
        ?.firstWhere((s) => s['_id'] == 'pending', orElse: () => {'count': 0})['count'] ?? 0;
    final shortlisted = analytics['applicationStats']
        ?.firstWhere((s) => s['_id'] == 'shortlisted', orElse: () => {'count': 0})['count'] ?? 0;
    final rejected = analytics['applicationStats']
        ?.firstWhere((s) => s['_id'] == 'rejected', orElse: () => {'count': 0})['count'] ?? 0;

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: pending.toDouble(),
            title: 'Pending',
            color: AppColors.warning,
            radius: 100,
          ),
          PieChartSectionData(
            value: shortlisted.toDouble(),
            title: 'Shortlisted',
            color: AppColors.accent,
            radius: 100,
          ),
          PieChartSectionData(
            value: rejected.toDouble(),
            title: 'Rejected',
            color: AppColors.error,
            radius: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Chart Legend Item Widget
class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: AppSpacing.cardShadow,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMutedLight.shade700,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? trend;
  final bool? isPositive;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.trend,
    this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive == true ? Icons.trending_up : Icons.trending_down,
                  size: 12,
                  color: isPositive == true ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 2),
                Text(
                  trend!,
                  style: TextStyle(
                    fontSize: 10,
                    color: isPositive == true ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}