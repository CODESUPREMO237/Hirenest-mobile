// MainPage with Role-based Navigation (Job Seeker, Employer, Guest)
// lib/features/home/presentation/pages/main_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../marketplace/presentation/pages/marketplace_page.dart';
import '../../../jobs/presentation/pages/jobs_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../pages/home_page.dart';
import '../pages/employer_dashboard.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final userAsync = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userRole = user.role;
        final isEmployer = userRole == 'employer';
        final isAdmin = user.isAdmin == true;

        if (isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              GoRouter.of(context).go('/admin/dashboard');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Different pages based on user role
        final pages = isEmployer
            ? [
                const EmployerDashboardPage(),
                const MarketplacePage(),
                const JobsPage(),
                const ChatListPage(),
                const ProfilePage(),
              ]
            : [
                const HomePageSimple(),
                const MarketplacePage(),
                const JobsPage(),
                const ChatListPage(),
                const ProfilePage(),
              ];

        void handleTabTap(int index) {
          ref.read(selectedIndexProvider.notifier).state = index;
        }

        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: isDark ? null : AppSpacing.bottomNavShadow,
              border: isDark ? const Border(top: BorderSide(color: AppColors.borderDark)) : null,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: isEmployer ? Icons.dashboard_rounded : Icons.home_rounded,
                      label: isEmployer ? 'Dashboard' : 'Home',
                      isSelected: selectedIndex == 0,
                      onTap: () => handleTabTap(0),
                    ),
                    _NavItem(
                      icon: Icons.storefront_rounded,
                      label: 'Market',
                      isSelected: selectedIndex == 1,
                      onTap: () => handleTabTap(1),
                    ),
                    _NavItem(
                      icon: Icons.work_rounded,
                      label: isEmployer ? 'My Jobs' : 'Jobs',
                      isSelected: selectedIndex == 2,
                      onTap: () => handleTabTap(2),
                    ),
                    _NavItem(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Chats',
                      isSelected: selectedIndex == 3,
                      onTap: () => handleTabTap(3),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: selectedIndex == 4,
                      onTap: () => handleTabTap(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Error loading user: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppAnimations.medium,
        curve: AppAnimations.standard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: AppSpacing.roundedFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : theme.bottomNavigationBarTheme.unselectedItemColor,
              size: 24,
            ),
            AnimatedSize(
              duration: AppAnimations.medium,
              curve: AppAnimations.standard,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}