// Profile Header - Fixed
// =====================================================
// lib/features/profile/presentation/widgets/profile_header.dart
// =====================================================
import 'package:flutter/material.dart';
import '../../../profile/data/models/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel user;
  final VoidCallback? onEditTap;

  const ProfileHeader({
    super.key,
    required this.user,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.profile?.avatar != null
                    ? NetworkImage(user.profile!.avatar!)
                    : null,
                child: user.profile?.avatar == null
                    ? Text(
                  user.profile?.initials ?? 'U',
                  style: const TextStyle(fontSize: 32),
                )
                    : null,
              ),
              if (onEditTap != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onEditTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Display name
          Text(
            user.profile?.displayName ?? user.email.split('@').first,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          // Role badge
          Chip(
            label: Text(
              user.role.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    );
  }
}