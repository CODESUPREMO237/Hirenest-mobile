// ============================================================================
// MODERN PRIVACY POLICY PAGE
// lib/features/profile/presentation/pages/privacy_policy_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar.large(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 80,
                    color: AppColors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Last Updated Badge
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary[50],
                      borderRadius: AppSpacing.roundedXl,
                      border: Border.all(color: AppColors.primary[100]),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.update, size: 16, color: AppColors.primary[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Last Updated: December 22, 2025',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Introduction Card
                _buildModernCard(
                  context,
                  icon: Icons.handshake_outlined,
                  color: AppColors.cta,
                  title: 'Our Commitment',
                  content:
                  'Welcome to HireNest. We respect your privacy and are committed to protecting your personal data. '
                      'This policy explains how we collect, use, and safeguard your information.',
                ),

                // Information Collection
                _buildExpandableSection(
                  context,
                  icon: Icons.collections_bookmark_outlined,
                  color: AppColors.primary,
                  title: 'Information We Collect',
                  items: [
                    _buildInfoItem(
                      'Personal Information',
                      '• Full name and email address\n'
                          '• Phone number (optional)\n'
                          '• Professional details (job title, company)\n'
                          '• Profile photo and documents',
                      Icons.person_outline,
                      AppColors.primary,
                    ),
                    _buildInfoItem(
                      'Automatic Data',
                      '• Device information and identifiers\n'
                          '• Usage patterns and interactions\n'
                          '• Location data (with permission)\n'
                          '• Log data and access times',
                      Icons.phone_android_outlined,
                      AppColors.primary,
                    ),
                  ],
                ),

                // How We Use Data
                _buildExpandableSection(
                  context,
                  icon: Icons.settings_suggest_outlined,
                  color: AppColors.success,
                  title: 'How We Use Your Data',
                  items: [
                    _buildBulletList([
                      'Create and manage your account',
                      'Connect you with job opportunities',
                      'Personalize your experience',
                      'Send relevant notifications',
                      'Improve our repositories',
                      'Ensure platform security',
                    ]),
                  ],
                ),

                // Data Sharing
                _buildExpandableSection(
                  context,
                  icon: Icons.share_outlined,
                  color: AppColors.warning,
                  title: 'Information Sharing',
                  items: [
                    _buildInfoItem(
                      'We Share With',
                      '• Employers (when you apply)\n'
                          '• Service providers (to operate)\n'
                          '• Legal authorities (when required)',
                      Icons.groups_outlined,
                      AppColors.warning,
                    ),
                    _buildHighlightBox(
                      'We Never Sell Your Data',
                      'Your personal information is not for sale to third parties.',
                      AppColors.success,
                    ),
                  ],
                ),

                // Security
                _buildModernCard(
                  context,
                  icon: Icons.security_outlined,
                  color: AppColors.error,
                  title: 'Data Security',
                  content:
                  'We implement industry-standard security measures:\n\n'
                      '🔒 End-to-end encryption\n'
                      '🛡️ Secure authentication\n'
                      '🔍 Regular security audits\n'
                      '👨‍💼 Staff training on data protection',
                ),

                // Your Rights
                _buildExpandableSection(
                  context,
                  icon: Icons.verified_user_outlined,
                  color: AppColors.primary,
                  title: 'Your Privacy Rights',
                  items: [
                    _buildRightsGrid(context),
                  ],
                ),

                // Data Retention
                _buildInfoCard(
                  context,
                  Icons.timer_outlined,
                  AppColors.secondary,
                  'Data Retention',
                  'We keep your data while your account is active. After deletion, '
                      'data is removed within 30 days, except where legally required.',
                ),

                // Cookies
                _buildInfoCard(
                  context,
                  Icons.cookie_outlined,
                  AppColors.textPrimaryLight,
                  'Cookies & Tracking',
                  'We use cookies to remember preferences, analyze usage, and improve performance. '
                      'Control these through your device settings.',
                ),

                // Children's Privacy
                _buildInfoCard(
                  context,
                  Icons.child_care_outlined,
                  AppColors.error,
                  'Children\'s Privacy',
                  'HireNest is for users 16+. We don\'t knowingly collect data from children. '
                      'Contact us if you believe we have.',
                ),

                // Contact Section
                _buildContactCard(context),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String content,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required List<Widget> items,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          childrenPadding: const EdgeInsets.all(20),
          children: items,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.textPrimaryLight),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHighlightBox(String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightsGrid(BuildContext context) {
    final rights = [
      {'icon': Icons.visibility, 'text': 'Access your data'},
      {'icon': Icons.edit, 'text': 'Correct information'},
      {'icon': Icons.delete, 'text': 'Delete account'},
      {'icon': Icons.download, 'text': 'Export data'},
      {'icon': Icons.unsubscribe, 'text': 'Opt-out marketing'},
      {'icon': Icons.privacy_tip, 'text': 'Control visibility'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: rights.length,
      itemBuilder: (context, index) {
        final right = rights[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: AppSpacing.roundedMd,
          ),
          child: Row(
            children: [
              Icon(right['icon'] as IconData, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  right['text'] as String,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
      BuildContext context,
      IconData icon,
      Color color,
      String title,
      String content,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppSpacing.roundedMd,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary[700], AppColors.primary[500]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.roundedXl,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent, color: AppColors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Questions About Privacy?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'re here to help',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: AppSpacing.roundedMd,
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.email, color: AppColors.white, size: 18),
                    SizedBox(width: 12),
                    Text(
                      'privacy@HireNest.com',
                      style: TextStyle(color: AppColors.white, fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.support, color: AppColors.white, size: 18),
                    SizedBox(width: 12),
                    Text(
                      'In-app support available',
                      style: TextStyle(color: AppColors.white, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}