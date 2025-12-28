// MainPage with Role-based Navigation (Job Seeker, Employer, Guest)
// lib/features/home/presentation/pages/main_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../marketplace/presentation/pages/marketplace_page.dart';
import '../../../jobs/presentation/pages/jobs_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../pages/home_page.dart';
import '../pages/employer_dashboard.dart';
import '../pages/guest_dashboard.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class MainPage extends ConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userRole = user.role ?? 'guest';
        final isEmployer = userRole == 'employer';
        final isGuest = userRole == 'guest' || userRole.isEmpty;

        // Different pages based on user role
        final pages = isGuest
            ? [
          const GuestDashboard(),
          const MarketplacePage(),
          const JobsPage(),
          const GuestDashboard(), // Placeholder for disabled chat
          const ProfilePage(),
        ]
            : isEmployer
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

        // Different nav items based on user role
        final navigationDestinations = isGuest
            ? [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('Limited'),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_bag),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('Limited'),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.work_outline),
            ),
            selectedIcon: const Icon(Icons.work),
            label: 'Jobs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.block_outlined),
            selectedIcon: Icon(Icons.block),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ]
            : isEmployer
            ? const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'My Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ]
            : const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Marketplace',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                // Prevent navigation to chat for guests
                if (isGuest && index == 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat is disabled for guest users. Please sign up!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                ref.read(selectedIndexProvider.notifier).state = index;
              },
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 70,
              destinations: navigationDestinations,
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading user: $error'),
            ],
          ),
        ),
      ),
    );
  }
}