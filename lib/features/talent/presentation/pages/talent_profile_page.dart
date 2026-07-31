// lib/features/talent/presentation/pages/talent_profile_page.dart

import 'package:flutter/material.dart';
import '../../../../core/widgets/error_widget.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';

final talentProfileInfoProvider = FutureProvider.family<UserModel, String>((ref, userId) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiEndpoints.userById(userId));
  if (response.data['status'] == 'success') {
    return UserModel.fromJson(response.data['data']['user']);
  }
  throw Exception('Failed to load user profile');
});

class TalentProfilePage extends ConsumerWidget {
  final String userId;

  const TalentProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talentAsync = ref.watch(talentProfileInfoProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: talentAsync.when(
        data: (user) {
          final profile = user.profile;
          final jobSeeker = user.jobSeekerProfile;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: AppColors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(context, user),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio / About
                      if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
                        _buildSectionContainer(
                          context,
                          title: 'About',
                          child: Text(
                            profile.bio!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondaryLight,
                                  height: 1.6,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Skills
                      if (jobSeeker?.skills != null && jobSeeker!.skills!.isNotEmpty) ...[
                        _buildSectionContainer(
                          context,
                          title: 'Top Skills',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: jobSeeker.skills!
                                .map((skill) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: AppSpacing.roundedFull,
                                      ),
                                      child: Text(
                                        skill.name ?? '',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Experience
                      if (jobSeeker?.experience != null && jobSeeker!.experience!.isNotEmpty) ...[
                        _buildSectionContainer(
                          context,
                          title: 'Experience',
                          child: Column(
                            children: jobSeeker.experience!.map((exp) => _buildExperienceItem(context, exp)).toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Education
                      if (jobSeeker?.education != null && jobSeeker!.education!.isNotEmpty) ...[
                        _buildSectionContainer(
                          context,
                          title: 'Education',
                          child: Column(
                            children: jobSeeker.education!.map((edu) => _buildEducationItem(context, edu)).toList(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      
                      const SizedBox(height: 80), // Padding for FAB
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => CustomErrorWidget(error: err),
      ),
      floatingActionButton: talentAsync.whenData((user) => FloatingActionButton.extended(
        onPressed: () => _handleContact(context, ref, user),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.message_outlined, size: 20),
        label: const Text('Message Candidate', style: TextStyle(fontWeight: FontWeight.w600)),
      )).valueOrNull,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 80, bottom: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.white,
              backgroundImage: user.profile?.avatar != null ? NetworkImage(user.profile!.avatar!) : null,
              child: user.profile?.avatar == null
                  ? const Icon(Icons.person, size: 50, color: AppColors.textMutedLight)
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (user.profile?.headline != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg),
              child: Text(
                user.profile!.headline!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.white.withValues(alpha: 0.8), size: 16),
              const SizedBox(width: 4),
              Text(
                user.profile?.location?.city ?? 'Location not specified',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedXl,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildExperienceItem(BuildContext context, ExperienceData exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.work_outline, color: AppColors.textSecondaryLight, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.position ?? 'Unknown Position',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  exp.company ?? 'Unknown Company',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(exp.startDate)} - ${_formatDate(exp.endDate, exp.current)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                ),
                if (exp.description != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    exp.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                          height: 1.5,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(BuildContext context, EducationData edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.school_outlined, color: AppColors.textSecondaryLight, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  edu.institution ?? 'Unknown Institution',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  edu.degree ?? 'Unknown Degree',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${edu.startYear ?? ''} - ${edu.endYear ?? (edu.current == true ? 'Present' : '')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date, [bool? current]) {
    if (current == true) return 'Present';
    if (date == null) return '';
    return '${date.month}/${date.year}';
  }

  Future<void> _handleContact(BuildContext context, WidgetRef ref, UserModel user) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      final repository = ref.read(chatRepositoryProvider);
      final String chatId = await repository.getOrCreateChat(
        receiverId: user.id,
        productId: null,
      );
      
      await repository.sendMessage(
        chatId,
        "Hi ${user.displayName}, I'm interested in discussing an opportunity with you."
      );

      if (context.mounted) {
        Navigator.pop(context);
        context.push('/chats/$chatId');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
      }
    }
  }
}
