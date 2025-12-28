// ============================================================================
// OAuth Configuration Diagnostic Tool
// Add this to a debug/test screen in your app to verify OAuth setup
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';

class OAuthDiagnosticScreen extends StatelessWidget {
  const OAuthDiagnosticScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OAuth Configuration Check'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'GitHub OAuth',
            [
              _ConfigItem(
                label: 'Client ID',
                value: AppConfig.githubClientId,
                isSecret: false,
              ),
              _ConfigItem(
                label: 'Redirect URI',
                value: AppConfig.githubRedirectUri,
                isSecret: false,
              ),
              _ConfigItem(
                label: 'Callback Scheme',
                value: _extractScheme(AppConfig.githubRedirectUri),
                isSecret: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Microsoft OAuth',
            [
              _ConfigItem(
                label: 'Client ID',
                value: AppConfig.microsoftClientId,
                isSecret: false,
              ),
              _ConfigItem(
                label: 'Redirect URI',
                value: AppConfig.microsoftRedirectUri,
                isSecret: false,
              ),
              _ConfigItem(
                label: 'Callback Scheme',
                value: _extractScheme(AppConfig.microsoftRedirectUri),
                isSecret: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Expected Values',
            [
              _InfoItem(
                label: 'GitHub Redirect URI',
                value: 'com.jobconnect://auth/github/callback',
                description: 'Must match AndroidManifest.xml and GitHub OAuth app settings',
              ),
              _InfoItem(
                label: 'Twitter Redirect URI',
                value: 'com.jobconnect://auth/twitter/callback',
                description: 'Must match AndroidManifest.xml and Twitter OAuth app settings',
              ),
              _InfoItem(
                label: 'Callback Scheme',
                value: 'com.jobconnect',
                description: 'Used by FlutterWebAuth2.authenticate()',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildValidationSection(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildValidationSection() {
    final githubValid = _validateGithubConfig();
    final twitterValid = _validateTwitterConfig();

    return Card(
      color: (githubValid && twitterValid) ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  (githubValid && twitterValid) ? Icons.check_circle : Icons.error,
                  color: (githubValid && twitterValid) ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Validation Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _ValidationItem(
              label: 'GitHub Configuration',
              isValid: githubValid,
              message: githubValid
                  ? 'All GitHub OAuth settings are configured'
                  : 'GitHub OAuth is missing required configuration',
            ),
            _ValidationItem(
              label: 'Twitter Configuration',
              isValid: twitterValid,
              message: twitterValid
                  ? 'All Twitter OAuth settings are configured'
                  : 'Twitter OAuth is missing required configuration',
            ),
            if (!githubValid || !twitterValid) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Action Required:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Check your .env file has all OAuth values\n'
                          '2. Run: flutter clean && flutter pub get\n'
                          '3. Restart your app\n'
                          '4. Verify OAuth provider settings match redirect URIs',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _extractScheme(String uri) {
    if (uri.isEmpty) return 'NOT SET';
    return uri.split('://').first;
  }

  bool _validateGithubConfig() {
    return AppConfig.githubClientId.isNotEmpty &&
        AppConfig.githubRedirectUri.isNotEmpty &&
        AppConfig.githubRedirectUri.contains('://');
  }

  bool _validateTwitterConfig() {
    return AppConfig.microsoftClientId.isNotEmpty &&
        AppConfig.microsoftRedirectUri.isNotEmpty &&
        AppConfig.microsoftRedirectUri.contains('://');
  }
}

class _ConfigItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isSecret;

  const _ConfigItem({
    required this.label,
    required this.value,
    this.isSecret = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty
        ? '❌ NOT SET'
        : isSecret
        ? '${value.substring(0, 10)}...'
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    color: value.isEmpty ? Colors.red : Colors.blue[700],
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              if (value.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label copied to clipboard')),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final String description;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.blue[900],
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationItem extends StatelessWidget {
  final String label;
  final bool isValid;
  final String message;

  const _ValidationItem({
    required this.label,
    required this.isValid,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}