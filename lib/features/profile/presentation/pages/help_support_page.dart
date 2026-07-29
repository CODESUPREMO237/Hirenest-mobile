// ============================================================================
// HELP & SUPPORT PAGE
// lib/features/profile/presentation/pages/help_support_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends ConsumerWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMutedLight),
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedLg,
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
              ),
              onSubmitted: (query) {
                // Search help articles
              },
            ),
          ),

          _buildSectionHeader(context, 'Quick Actions'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Live Chat',
                    color: AppColors.primary,
                    onTap: () => _startLiveChat(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.email_outlined,
                    title: 'Email Us',
                    color: AppColors.success,
                    onTap: () => _sendEmail(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.phone_outlined,
                    title: 'Call Support',
                    color: AppColors.warning,
                    onTap: () => _callSupport(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.bug_report_outlined,
                    title: 'Report Bug',
                    color: AppColors.error,
                    onTap: () => _reportBug(context),
                  ),
                ),
              ],
            ),
          ),

          _buildSectionHeader(context, 'Frequently Asked Questions'),
          _buildFAQSection(context),

          _buildSectionHeader(context, 'Help Categories'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Column(
              children: [
                _buildHelpCategory(context, Icons.work_outline_rounded, 'Jobs & Applications', 'Learn about job searching and applications'),
                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                _buildHelpCategory(context, Icons.shopping_bag_outlined, 'Marketplace', 'Buying and selling on HireNest'),
                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                _buildHelpCategory(context, Icons.payment_outlined, 'Payments & Transactions', 'Payment methods and transaction history'),
                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                _buildHelpCategory(context, Icons.account_circle_outlined, 'Account Management', 'Profile settings and security'),
              ],
            ),
          ),

          _buildSectionHeader(context, 'Community'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Column(
              children: [
                _buildCommunityTile(context, Icons.forum_outlined, 'Community Forum', 'Ask questions and share tips', _openForum),
                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                _buildCommunityTile(context, Icons.school_outlined, 'Video Tutorials', 'Learn with video guides', _openTutorials),
                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                _buildCommunityTile(context, Icons.article_outlined, 'Help Center', 'Browse detailed guides', _openHelpCenter),
              ],
            ),
          ),

          _buildSectionHeader(context, 'Contact Information'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactInfo(context, Icons.email_rounded, 'support@HireNest.com'),
                const SizedBox(height: AppSpacing.md),
                _buildContactInfo(context, Icons.phone_rounded, '+237 679 398 551'),
                const SizedBox(height: AppSpacing.md),
                _buildContactInfo(context, Icons.schedule_rounded, 'Mon-Fri: 8AM - 6PM WAT'),
                const SizedBox(height: AppSpacing.md),
                _buildContactInfo(context, Icons.location_on_rounded, 'Tiko, South-West, Cameroon'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textMutedLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      _FAQItem('How do I apply for a job?', 'Browse jobs, click on a job listing, and tap the "Apply" button. Fill in your application details and submit.'),
      _FAQItem('How do I list a product for sale?', 'Go to Marketplace, tap the "+" button, add product details, upload photos, and publish your listing.'),
      _FAQItem('How long does payment take?', 'Payments are processed within 24-48 hours after successful transaction confirmation.'),
      _FAQItem('How do I change my password?', 'Go to Profile > Settings > Privacy & Security > Change Password.'),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: faqs.length,
      itemBuilder: (context, index) => _buildFAQCard(context, faqs[index]),
    );
  }

  Widget _buildFAQCard(BuildContext context, _FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
          title: Text(
            faq.question,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
              child: Text(faq.answer, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCategory(BuildContext context, IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: AppSpacing.roundedSm,
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMutedLight),
      onTap: () {},
    );
  }

  Widget _buildCommunityTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: Icon(icon, color: AppColors.textSecondaryLight),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight)),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textMutedLight),
      onTap: onTap,
    );
  }

  Widget _buildContactInfo(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
          ),
        ),
      ],
    );
  }

  void _startLiveChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
        title: const Text('Live Chat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Our support team is available Mon-Fri, 8AM-6PM WAT.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('Would you like to start a chat session?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg)), child: const Text('Start Chat')),
        ],
      ),
    );
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: 'support@HireNest.com', query: 'subject=Support Request');
    if (await canLaunchUrl(emailUri)) await launchUrl(emailUri);
  }

  Future<void> _callSupport() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+237679398551');
    if (await canLaunchUrl(phoneUri)) await launchUrl(phoneUri);
  }

  void _reportBug(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Bug Title', border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg))),
            const SizedBox(height: AppSpacing.md),
            TextField(maxLines: 4, decoration: InputDecoration(labelText: 'Description', hintText: 'Describe the issue...', border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg)), child: const Text('Submit')),
        ],
      ),
    );
  }

  void _openForum() {}
  void _openTutorials() {}
  void _openHelpCenter() {}
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedLg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppSpacing.roundedLg,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;
  _FAQItem(this.question, this.answer);
}