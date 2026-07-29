// ============================================================================
// ABOUT PAGE (MODERN UPDATED VERSION)
// lib/features/profile/presentation/pages/about_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppSpacing.roundedXl,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(
                    Icons.work_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'HireNest',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Marketplace & Jobs Platform',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: AppSpacing.roundedFull,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    'Version $_appVersion',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMutedLight),
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'Our Mission',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'To connect job seekers with opportunities and enable seamless buying and selling in local communities.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildSectionHeader(context, 'Features'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Column(
              children: [
                _buildFeatureTile(context, Icons.work_outline_rounded, 'Job Search', 'Browse and apply for jobs', AppColors.primary),
                const Divider(height: 1, color: AppColors.borderLight, indent: 70),
                _buildFeatureTile(context, Icons.shopping_bag_outlined, 'Marketplace', 'Buy and sell products locally', AppColors.success),
                const Divider(height: 1, color: AppColors.borderLight, indent: 70),
                _buildFeatureTile(context, Icons.chat_bubble_outline_rounded, 'Chat', 'Connect with buyers and sellers', AppColors.warning),
                const Divider(height: 1, color: AppColors.borderLight, indent: 70),
                _buildFeatureTile(context, Icons.payment_rounded, 'Secure Payments', 'Safe and secure transactions', AppColors.accent),
              ],
            ),
          ),

          _buildSectionHeader(context, 'Company'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Column(
              children: [
                _buildListTile(context, Icons.business_rounded, 'About Us', 'Learn more about our company', () => _launchURL('https://HireNest.com/about')),
                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                _buildListTile(context, Icons.people_outline_rounded, 'Our Team', 'Meet the people behind HireNest', () => _launchURL('https://HireNest.com/team')),
                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                _buildListTile(context, Icons.article_outlined, 'Blog', 'News and updates', () => _launchURL('https://HireNest.com/blog')),
              ],
            ),
          ),

          _buildSectionHeader(context, 'Connect With Us'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(context, FontAwesomeIcons.facebook, 'Facebook', const Color(0xFF1877F2), () => _launchURL('https://facebook.com/HireNest')),
                _buildSocialButton(context, FontAwesomeIcons.xTwitter, 'X', AppColors.black, () => _launchURL('https://twitter.com/HireNest')),
                _buildSocialButton(context, FontAwesomeIcons.instagram, 'Instagram', const Color(0xFFE4405F), () => _launchURL('https://instagram.com/HireNest')),
                _buildSocialButton(context, FontAwesomeIcons.linkedinIn, 'LinkedIn', const Color(0xFF0A66C2), () => _launchURL('https://linkedin.com/company/HireNest')),
              ],
            ),
          ),

          _buildSectionHeader(context, 'Legal'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Column(
              children: [
                _buildListTile(context, Icons.description_outlined, 'Terms of Service', null, () => context.push('/profile/legal/terms')),
                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                _buildListTile(context, Icons.privacy_tip_outlined, 'Privacy Policy', null, () => context.push('/profile/legal/privacy')),
                const Divider(height: 1, color: AppColors.borderLight, indent: 56),
                _buildListTile(context, Icons.gavel_rounded, 'Licenses', null, () => _showLicensesDialog()),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              borderRadius: AppSpacing.roundedLg,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.star_rounded, color: AppColors.accent),
              title: Text('Rate Our App', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.accent)),
              subtitle: Text('Help us improve with your feedback', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
              onTap: () => _rateApp(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Column(
              children: [
                Text('© 2025 HireNest', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textMutedLight, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Made with ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMutedLight)),
                    const Icon(Icons.favorite, color: AppColors.error, size: 14),
                    Text(' in Cameroon', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMutedLight)),
                  ],
                ),
              ],
            ),
          ),
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

  Widget _buildFeatureTile(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppSpacing.roundedMd,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: Icon(icon, color: AppColors.textSecondaryLight),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight)),
      subtitle: subtitle != null ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMutedLight)) : null,
      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textMutedLight),
      onTap: onTap,
    );
  }

  Widget _buildSocialButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedLg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceLight,
              border: Border.all(color: AppColors.borderLight, width: 1.5),
              boxShadow: AppSpacing.cardShadow,
            ),
            child: FaIcon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  void _showLicensesDialog() {
    context.push('/profile/legal/licenses');
  }

  void _rateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
        title: const Text('Rate HireNest'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you rate your experience?'),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => Icon(Icons.star_border_rounded, size: 40, color: AppColors.accent.withValues(alpha: 0.4))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context), 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg)),
            child: const Text('Rate Now')
          ),
        ],
      ),
    );
  }
}