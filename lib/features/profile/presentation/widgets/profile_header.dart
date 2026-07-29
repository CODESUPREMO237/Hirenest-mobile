// Profile Header - Fixed
// =====================================================
// lib/features/profile/presentation/widgets/profile_header.dart
// =====================================================
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppSpacing.cardShadow,
                  border: Border.all(color: AppColors.borderLight, width: 2),
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.backgroundLight,
                  backgroundImage: user.profile?.avatar != null
                      ? NetworkImage(user.profile!.avatar!)
                      : null,
                  child: user.profile?.avatar == null
                      ? Text(
                          user.profile?.initials ?? 'U',
                          style: textTheme.headlineMedium?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              if (onEditTap != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onEditTap,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surfaceLight,
                          width: 3,
                        ),
                        boxShadow: AppSpacing.elevatedShadow,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Display name
          Text(
            user.profile?.displayName ?? user.email.split('@').first,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Email
          Text(
            user.email,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedFull,
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}