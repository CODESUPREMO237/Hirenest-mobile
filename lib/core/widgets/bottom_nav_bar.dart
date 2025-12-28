// =====================================================
// BOTTOM NAVIGATION (Optional Helper)
// lib/core/widgets/bottom_nav_bar.dart
// =====================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/jobs');
            break;
          case 2:
            context.go('/marketplace');
            break;
          case 3:
            context.go('/chats');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: 'Jobs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Market',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}