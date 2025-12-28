// ============================================================================
// PRIVACY & SECURITY PAGE (COMPLETE UPDATED VERSION)
// lib/features/profile/presentation/pages/privacy_security_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/utils/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Import your custom error widget
import '../../../../core/widgets/error_widget.dart';
import '../providers/profile_provider.dart';
import '../../data/repositories/profile_repository.dart';

class PrivacySecurityPage extends ConsumerStatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  ConsumerState<PrivacySecurityPage> createState() =>
      _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends ConsumerState<PrivacySecurityPage> {
  bool _profileVisibility = true;
  bool _showEmail = false;
  bool _showPhone = false;
  final LocalAuthentication auth = LocalAuthentication();
  // Inside _PrivacySecurityPageState class
  final _storage = const FlutterSecureStorage(); // Define storage here

  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;

  bool _loading = true;
  String? _pageError; // Track errors to show CustomErrorWidget

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    // Use .maybeWhen or check for hasValue to prevent crashes during initial load
    final profileAsync = ref.read(profileProvider);

    if (profileAsync.hasValue) {
      final profile = profileAsync.value;
      if (profile != null && mounted) {
        setState(() {
          _profileVisibility = profile.privacySettings?.profileVisibility == 'public';
          _showEmail = profile.privacySettings?.showEmail ?? false;
          _showPhone = profile.privacySettings?.showPhone ?? false;
          _biometricEnabled = profile.privacySettings?.biometricLogin ?? false;
          _loading = false;
          _pageError = null;
        });
      }
    }
  }

  // ========================================================================
  // BIOMETRIC LOGIC WITH ERROR WIDGET INTEGRATION
  // ========================================================================
  Future<void> _toggleBiometrics(bool enabled) async {
    if (!enabled) {
      setState(() => _biometricEnabled = false);
      // Clear secure storage when disabling
      await _storage.delete(key: 'saved_email');
      await _storage.delete(key: 'saved_password');
      await _updatePrivacy(biometricLogin: false);
      return;
    }

    setState(() => _pageError = null);

    try {
      print("========== BIOMETRIC DEBUG ==========");

      final bool available = await auth.canCheckBiometrics;
      final bool supported = await auth.isDeviceSupported();
      final List<BiometricType> biometrics = await auth.getAvailableBiometrics();

      print("canCheckBiometrics: $available");
      print("isDeviceSupported: $supported");
      print("availableBiometrics: $biometrics");

      if (!available || !supported || biometrics.isEmpty) {
        throw Exception("Biometrics not supported or no types registered.");
      }

      print("Running biometric authentication…");

      final authenticated = await auth.authenticate(
        localizedReason: "Please authenticate to enable biometric login",
        biometricOnly: true,
        sensitiveTransaction: true,
      );

      print("Biometric result: $authenticated");

      if (!mounted) return;

      setState(() => _biometricEnabled = authenticated);

      if (authenticated) {
        setState(() => _biometricEnabled = true);
        // PERSIST THE DATA TO BACKEND
        await _updatePrivacy(biometricLogin: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Biometric login enabled")),
        );
      }

      print("=====================================");
    } catch (e, s) {
      print("❌ BIOMETRIC ERROR: $e");
      print("❌ STACK TRACE: $s");

      if (!mounted) return;

      setState(() {
        _biometricEnabled = false;
        _pageError = e.toString().contains('NotAvailable')
            ? "Biometric hardware not found."
            : "Could not complete biometric setup.";
      });
    }
  }



  // ========================================================================
  // SESSION MANAGEMENT
  // ========================================================================
  Future<void> _logoutDevice(String tokenId) async {
    try {
      await ref.read(profileRepositoryProvider).removeSession(tokenId);
      ref.invalidate(profileProvider);

      if (!mounted) return;
      Navigator.pop(context); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device logged out successfully')),
      );
    } catch (e) {
      AppLogger.error('Logout device error', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showActiveSessionsDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final sessions = await ref.read(profileRepositoryProvider).getActiveSessions();
      if (!mounted) return;
      Navigator.pop(context); // Remove loader

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Active Sessions'),
          content: sessions.isEmpty
              ? const Text('No other active sessions found.')
              : SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return ListTile(
                  leading: const Icon(Icons.devices),
                  title: Text(session['device'] ?? 'Unknown Device'),
                  subtitle: Text('Added: ${session['addedAt'] ?? 'Unknown'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: () => _logoutDevice(session['_id']),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loader
      setState(() => _pageError = "Could not fetch active sessions.");
    }
  }

  // ========================================================================
  // PASSWORD RESET
  // ========================================================================
  Future<void> _handlePasswordResetRequest() async {
    final profile = ref.read(profileProvider).value;
    if (profile?.email == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending reset link...')),
      );
      await ref.read(profileRepositoryProvider).requestPasswordReset(profile!.email!);
      if (!mounted) return;
      _showSuccessDialog('Email Sent', 'Password reset link sent to ${profile.email}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updatePrivacy({String? profileVisibility, bool? showEmail, bool? showPhone, bool? biometricLogin, }) async {
    try {
      await ref.read(profileRepositoryProvider).updatePrivacySettings(
        profileVisibility: profileVisibility,
        showEmail: showEmail,
        showPhone: showPhone,
        biometricLogin: biometricLogin, // Pass it through
      );
      ref.invalidate(profileProvider);
    } catch (e) {
      AppLogger.error('Privacy update error', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If a significant error occurred (like biometric failure), show ErrorWidget
    if (_pageError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Security Error')),
        body: CustomErrorWidget(
          message: _pageError!,
          onRetry: () {
            setState(() => _pageError = null);
            _loadPrivacy();
          },
        ),
      );
    }

    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: profileAsync.when(
        data: (_) => _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
        error: (e, _) => CustomErrorWidget(message: e.toString(), onRetry: () => ref.refresh(profileProvider)),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        _buildSectionHeader('Privacy Settings'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.visibility_outlined),
                title: const Text('Public Profile'),
                value: _profileVisibility,
                onChanged: (value) async {
                  setState(() => _profileVisibility = value);
                  await _updatePrivacy(profileVisibility: value ? 'public' : 'private');
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.email_outlined),
                title: const Text('Show Email'),
                value: _showEmail,
                onChanged: _profileVisibility ? (value) async {
                  setState(() => _showEmail = value);
                  await _updatePrivacy(showEmail: value);
                } : null,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.phone_outlined),
                title: const Text('Show Phone'),
                value: _showPhone,
                onChanged: _profileVisibility ? (value) async {
                  setState(() => _showPhone = value);
                  await _updatePrivacy(showPhone: value);
                } : null,
              ),
            ],
          ),
        ),

        _buildSectionHeader('Security Settings'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.send_outlined),
                onTap: _handlePasswordResetRequest,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Biometric Login'),
                value: _biometricEnabled,
                onChanged: _toggleBiometrics,
              ),
            ],
          ),
        ),

        _buildSectionHeader('Account Management'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.devices_outlined),
                title: const Text('Active Sessions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showActiveSessionsDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                onTap: _showDeleteAccountDialog,
              ),
            ],
          ),
        ),

        _buildSectionHeader('Legal'),
        _buildLegalLinks(),
        const SizedBox(height: 32),
      ],
    );
  }

  // --- Helper UI components ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  Widget _buildLegalLinks() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () => context.push('/profile/legal/privacy'),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            onTap: () => context.push('/profile/legal/terms'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action is permanent. Do you want to continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => context.go('/auth/login'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}