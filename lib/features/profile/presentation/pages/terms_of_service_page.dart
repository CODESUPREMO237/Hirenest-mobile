// ============================================================================
// MODERN TERMS OF SERVICE PAGE
// lib/features/profile/presentation/pages/terms_of_service_page.dart
// ============================================================================

import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar.large(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Terms of Service',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple[700]!,
                      Colors.deepPurple[400]!,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.gavel,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
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
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.update, size: 16, color: Colors.amber[800]),
                        const SizedBox(width: 8),
                        Text(
                          'Last Updated: December 22, 2025',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Agreement Notice
                _buildNoticeCard(
                  context,
                  'By using JobConnect, you agree to these terms. Please read carefully.',
                  Colors.deepPurple,
                  Icons.verified_user,
                ),

                // Eligibility
                _buildModernSection(
                  context,
                  icon: Icons.how_to_reg_outlined,
                  color: Colors.blue,
                  title: 'Eligibility',
                  items: [
                    _buildCheckItem('Be at least 16 years old'),
                    _buildCheckItem('Have legal capacity for contracts'),
                    _buildCheckItem('Provide accurate information'),
                    _buildCheckItem('Keep credentials secure'),
                  ],
                ),

                // Account Management
                _buildExpandableCard(
                  context,
                  icon: Icons.account_circle_outlined,
                  color: Colors.green,
                  title: 'Your Account',
                  content: [
                    _buildSubSection(
                      'Responsibilities',
                      '• Maintain credential confidentiality\n'
                          '• Monitor account activity\n'
                          '• Report unauthorized access\n'
                          '• Keep profile information current',
                      Icons.shield_outlined,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildAccountTypesCard(),
                  ],
                ),

                // Acceptable Use
                _buildExpandableCard(
                  context,
                  icon: Icons.policy_outlined,
                  color: Colors.orange,
                  title: 'Acceptable Use',
                  content: [
                    _buildProhibitedList(),
                  ],
                ),

                // Content & IP
                _buildExpandableCard(
                  context,
                  icon: Icons.copyright_outlined,
                  color: Colors.purple,
                  title: 'Content & Intellectual Property',
                  content: [
                    _buildIPCard(context),
                  ],
                ),

                // Job Postings
                _buildExpandableCard(
                  context,
                  icon: Icons.work_outline,
                  color: Colors.teal,
                  title: 'Job Postings & Applications',
                  content: [
                    _buildJobGuidelines(context),
                  ],
                ),

                // Payments
                _buildIconCard(
                  context,
                  Icons.payment_outlined,
                  Colors.indigo,
                  'Payments & Subscriptions',
                  '• All fees in USD\n'
                      '• Auto-renewal unless cancelled\n'
                      '• Refunds per our policy\n'
                      '• 30-day notice for price changes\n\n'
                      'Cancel anytime in account settings.',
                ),

                // Privacy
                _buildLinkCard(
                  context,
                  Icons.privacy_tip_outlined,
                  Colors.blue,
                  'Privacy & Data Protection',
                  'Your privacy matters. See our Privacy Policy for details on data handling.',
                ),

                // Disclaimers
                _buildWarningCard(
                  context,
                  'Service Disclaimers',
                  [
                    'Service provided "as is"',
                    'No guarantee of uninterrupted access',
                    'Content accuracy not guaranteed',
                    'No employment outcome guarantees',
                  ],
                ),

                // Termination
                _buildIconCard(
                  context,
                  Icons.block_outlined,
                  Colors.red,
                  'Account Termination',
                  'We may suspend/terminate accounts for:\n\n'
                      '• Terms violations\n'
                      '• Fraudulent activity\n'
                      '• Extended inactivity\n'
                      '• Legal requirements\n\n'
                      'You can delete your account anytime.',
                ),

                // Dispute Resolution
                _buildExpandableCard(
                  context,
                  icon: Icons.gavel_outlined,
                  color: Colors.brown,
                  title: 'Dispute Resolution',
                  content: [
                    _buildDisputeSteps(),
                  ],
                ),

                // Updates
                _buildIconCard(
                  context,
                  Icons.system_update_outlined,
                  Colors.cyan,
                  'Changes to Terms',
                  'We may update these terms. You\'ll be notified via:\n\n'
                      '📱 In-app notifications\n'
                      '📧 Email alerts\n'
                      '🔄 Updated date\n\n'
                      'Continued use means acceptance.',
                ),

                // Contact
                _buildContactCard(context),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(BuildContext context, String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required List<Widget> items,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCard(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required List<Widget> content,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          childrenPadding: const EdgeInsets.all(20),
          children: content,
        ),
      ),
    );
  }

  Widget _buildSubSection(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypesCard() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.person_search, color: Colors.blue[700], size: 28),
                const SizedBox(height: 8),
                const Text(
                  'Job Seekers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create profiles\nApply for jobs',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.business_center, color: Colors.purple[700], size: 28),
                const SizedBox(height: 8),
                const Text(
                  'Employers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Post jobs\nFind candidates',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProhibitedList() {
    final items = [
      'Post false or misleading information',
      'Impersonate others',
      'Harass or abuse users',
      'Post spam or advertisements',
      'Violate laws or regulations',
      'Attempt unauthorized access',
      'Use automated scraping tools',
      'Post discriminatory content',
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cancel, color: Colors.red[400], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIPCard(BuildContext context) {
    return Column(
      children: [
        _buildInfoBox(
          'Your Content',
          'You keep ownership. We get a license to display and distribute for service purposes.',
          Colors.purple,
          Icons.upload_file,
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          'Our Content',
          'JobConnect branding and features are protected. No copying or derivative works without permission.',
          Colors.deepPurple,
          Icons.copyright,
        ),
      ],
    );
  }

  Widget _buildJobGuidelines(BuildContext context) {
    return Column(
      children: [
        _buildInfoBox(
          'For Employers',
          'Post legitimate jobs only. Follow equal opportunity laws. No discriminatory language.',
          Colors.teal,
          Icons.work,
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          'For Job Seekers',
          'Be truthful. Don\'t misrepresent qualifications. Report suspicious postings.',
          Colors.cyan,
          Icons.person,
        ),
      ],
    );
  }

  Widget _buildInfoBox(String title, String content, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
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
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCard(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: color),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context, String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.amber[800], size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16, color: Colors.amber[900])),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDisputeSteps() {
    return Column(
      children: [
        _buildStepCard(1, 'Contact Us First', 'Reach out to resolve informally', Colors.blue),
        const SizedBox(height: 12),
        _buildStepCard(2, 'Arbitration', 'Binding arbitration in San Francisco, CA', Colors.orange),
        const SizedBox(height: 12),
        _buildStepCard(3, 'Waiver', 'No class action participation', Colors.red),
      ],
    );
  }

  Widget _buildStepCard(int step, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
          colors: [Colors.deepPurple[700]!, Colors.deepPurple[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.contact_support, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'re here to answer your questions',
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'legal@jobconnect.com',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.support_agent, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'support@jobconnect.com',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
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