// ============================================================================
// ABOUT PAGE (MODERN UPDATED VERSION)
// lib/features/profile/presentation/pages/about_page.dart
// ============================================================================

import 'package:flutter/material.dart';
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // --- App Logo and Info ---
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.15),
                        primaryColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Icon(
                    Icons.work_rounded, // Softer rounded icon
                    size: 80,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'JobConnect',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Marketplace & Jobs Platform',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version $_appVersion',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // --- Mission Statement ---
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, color: primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Our Mission',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To connect job seekers with opportunities and enable seamless buying and selling in local communities.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Features ---
          _buildSectionHeader('Features'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildFeatureTile(Icons.work_outline_rounded, 'Job Search', 'Browse and apply for jobs', Colors.blue),
                const Divider(height: 1, indent: 70),
                _buildFeatureTile(Icons.shopping_bag_outlined, 'Marketplace', 'Buy and sell products locally', Colors.green),
                const Divider(height: 1, indent: 70),
                _buildFeatureTile(Icons.chat_bubble_outline_rounded, 'Chat', 'Connect with buyers and sellers', Colors.orange),
                const Divider(height: 1, indent: 70),
                _buildFeatureTile(Icons.payment_rounded, 'Secure Payments', 'Safe and secure transactions', Colors.purple),
              ],
            ),
          ),

          // --- Company Section ---
          _buildSectionHeader('Company'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildListTile(Icons.business_rounded, 'About Us', 'Learn more about our company', () => _launchURL('https://jobconnect.com/about')),
                const Divider(height: 1, indent: 70),
                _buildListTile(Icons.people_outline_rounded, 'Our Team', 'Meet the people behind JobConnect', () => _launchURL('https://jobconnect.com/team')),
                const Divider(height: 1, indent: 70),
                _buildListTile(Icons.article_outlined, 'Blog', 'News and updates', () => _launchURL('https://jobconnect.com/blog')),
              ],
            ),
          ),

          // --- Social Media Section ---
          _buildSectionHeader('Connect With Us'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(FontAwesomeIcons.facebook, 'Facebook', const Color(0xFF1877F2), () => _launchURL('https://facebook.com/jobconnect')),
                _buildSocialButton(FontAwesomeIcons.xTwitter, 'X', Colors.black, () => _launchURL('https://twitter.com/jobconnect')),
                _buildSocialButton(FontAwesomeIcons.instagram, 'Instagram', const Color(0xFFE4405F), () => _launchURL('https://instagram.com/jobconnect')),
                _buildSocialButton(FontAwesomeIcons.linkedinIn, 'LinkedIn', const Color(0xFF0077B5), () => _launchURL('https://linkedin.com/company/jobconnect')),
              ],
            ),
          ),

          // --- Legal Section ---
          _buildSectionHeader('Legal'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildListTile(Icons.description_outlined, 'Terms of Service', null, () =>context.push('/profile/legal/terms')),
                const Divider(height: 1, indent: 70),
                _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy', null, () =>context.push('/profile/legal/privacy')),
                const Divider(height: 1, indent: 70),
                _buildListTile(Icons.gavel_rounded, 'Licenses', null, () => _showLicensesDialog()),
              ],
            ),
          ),

          // --- Rate App ---
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 0,
            color: Colors.amber.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.amber.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.amber),
              title: const Text('Rate Our App', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Help us improve with your feedback'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _rateApp(),
            ),
          ),

          // --- Credits ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text('© 2025 JobConnect', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Made with ', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const Icon(Icons.favorite, color: Colors.red, size: 14),
                    Text(' in Cameroon', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Methods ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
    );
  }

  Widget _buildListTile(IconData icon, String title, String? subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSocialButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
              color: Colors.white,
            ),
            child: FaIcon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.blueGrey[800], fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // --- Functional Methods ---

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  void _showLicensesDialog() {
    // // Option A: Use the built-in styled version
    // showLicensePage(
    //   context: context,
    //   applicationName: 'JobConnect',
    //   applicationVersion: _appVersion,
    //   applicationLegalese: '© 2025 JobConnect Team',
    //   applicationIcon: Container(
    //     padding: const EdgeInsets.all(12),
    //     decoration: BoxDecoration(
    //       color: Theme.of(context).primaryColor.withOpacity(0.1),
    //       shape: BoxShape.circle,
    //     ),
    //     child: Icon(Icons.work_rounded, size: 48, color: Theme.of(context).primaryColor),
    //   ),
    // );

    context.push('/profile/legal/licenses');
  }

  void _rateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rate JobConnect'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How would you rate your experience?'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => Icon(Icons.star_border_rounded, size: 40, color: Colors.amber.withOpacity(0.4))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Rate Now')),
        ],
      ),
    );
  }
}