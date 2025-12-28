// ============================================================================
// HELP & SUPPORT PAGE
// lib/features/profile/presentation/pages/help_support_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends ConsumerWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        children: [
          // Search Help
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (query) {
                // Search help articles
              },
            ),
          ),

          // Quick Actions
          _buildSectionHeader(context, 'Quick Actions'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.chat_bubble_outline,
                    title: 'Live Chat',
                    color: Colors.blue,
                    onTap: () => _startLiveChat(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.email_outlined,
                    title: 'Email Us',
                    color: Colors.green,
                    onTap: () => _sendEmail(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.phone_outlined,
                    title: 'Call Support',
                    color: Colors.orange,
                    onTap: () => _callSupport(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.bug_report_outlined,
                    title: 'Report Bug',
                    color: Colors.red,
                    onTap: () => _reportBug(context),
                  ),
                ),
              ],
            ),
          ),

          // FAQs
          _buildSectionHeader(context, 'Frequently Asked Questions'),
          _buildFAQSection(),

          // Help Categories
          _buildSectionHeader(context, 'Help Categories'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildHelpCategory(
                  context,
                  Icons.work_outline,
                  'Jobs & Applications',
                  'Learn about job searching and applications',
                ),
                const Divider(height: 1),
                _buildHelpCategory(
                  context,
                  Icons.shopping_bag_outlined,
                  'Marketplace',
                  'Buying and selling on JobConnect',
                ),
                const Divider(height: 1),
                _buildHelpCategory(
                  context,
                  Icons.payment_outlined,
                  'Payments & Transactions',
                  'Payment methods and transaction history',
                ),
                const Divider(height: 1),
                _buildHelpCategory(
                  context,
                  Icons.account_circle_outlined,
                  'Account Management',
                  'Profile settings and security',
                ),
              ],
            ),
          ),

          // Community
          _buildSectionHeader(context, 'Community'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: const Text('Community Forum'),
                  subtitle: const Text('Ask questions and share tips'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openForum(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Video Tutorials'),
                  subtitle: const Text('Learn with video guides'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openTutorials(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Help Center'),
                  subtitle: const Text('Browse detailed guides'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openHelpCenter(),
                ),
              ],
            ),
          ),

          // Contact Info
          _buildSectionHeader(context, 'Contact Information'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactInfo(Icons.email, 'support@jobconnect.com'),
                  const SizedBox(height: 12),
                  _buildContactInfo(Icons.phone, '+237 679 398 551'),
                  const SizedBox(height: 12),
                  _buildContactInfo(Icons.schedule, 'Mon-Fri: 8AM - 6PM WAT'),
                  const SizedBox(height: 12),
                  _buildContactInfo(Icons.location_on, 'Tiko, South-West, Cameroon'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      _FAQItem(
        'How do I apply for a job?',
        'Browse jobs, click on a job listing, and tap the "Apply" button. Fill in your application details and submit.',
      ),
      _FAQItem(
        'How do I list a product for sale?',
        'Go to Marketplace, tap the "+" button, add product details, upload photos, and publish your listing.',
      ),
      _FAQItem(
        'How long does payment take?',
        'Payments are processed within 24-48 hours after successful transaction confirmation.',
      ),
      _FAQItem(
        'How do I change my password?',
        'Go to Profile > Settings > Privacy & Security > Change Password.',
      ),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: faqs.length,
      itemBuilder: (context, index) => _buildFAQCard(faqs[index]),
    );
  }

  Widget _buildFAQCard(_FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        title: Text(
          faq.question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(faq.answer),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCategory(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Navigate to category details
      },
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  void _startLiveChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Our support team is available Mon-Fri, 8AM-6PM WAT.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Would you like to start a chat session?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open chat
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@jobconnect.com',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _callSupport() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+237679398551');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _reportBug(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Bug Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Describe the issue...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report submitted. Thank you!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _openForum() {
    // Open community forum URL
  }

  void _openTutorials() {
    // Open video tutorials
  }

  void _openHelpCenter() {
    // Open help center
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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