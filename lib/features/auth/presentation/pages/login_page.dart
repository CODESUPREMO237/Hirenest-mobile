// ============================================================================
// LOGIN PAGE WITH BIOMETRIC AUTHENTICATION
// lib/features/auth/presentation/pages/login_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


import '../../../../core/services/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/utils/logger.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isGithubLoading = false;
  bool _isMicrosoftLoading = false;
  bool _rememberMe = false;

  // Biometric
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    // We use addPostFrameCallback to ensure the UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometric();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===================== BIOMETRIC SETUP =====================

  Future<void> _checkBiometric() async {
    // 1. Give the UI a moment to settle
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final biometricService = ref.read(biometricServiceProvider);

      // 2. Check support and saved state
      final available = await biometricService.isBiometricAvailable();
      final enabled = await biometricService.isBiometricLoginEnabled();
      final hasCreds = await biometricService.hasSavedCredentials();

      AppLogger.info('Biometric Check: Available: $available, Enabled: $enabled, HasCreds: $hasCreds');

      if (available) {
        final types = await biometricService.getAvailableBiometrics();
        if (mounted) {
          setState(() {
            _biometricAvailable = true;
            _biometricEnabled = enabled;
            _biometricType = biometricService.getTypeName(types);
          });
        }

        // 3. AUTO-PROMPT LOGIC
        // If user enabled it and we have their email/pass stored locally
        if (enabled && hasCreds && mounted) {
          // A slightly longer delay ensures the OS bottom sheet doesn't conflict with transition animations
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _handleBiometricLogin();
          });
        }
      }
    } catch (e) {
      AppLogger.error('Biometric init error', error: e);
    }
  }

  // ===================== BIOMETRIC LOGIN =====================

  Future<void> _handleBiometricLogin() async {
    try {
      final biometricService = ref.read(biometricServiceProvider);

      // Authenticate with biometric
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to login to JobConnect',
      );

      if (!authenticated) return;

      // Get saved credentials
      final credentials = await biometricService.getSavedCredentials();

      if (credentials == null) {
        _showError('No saved credentials found. Please login with email/password first.');
        return;
      }

      setState(() => _isLoading = true);

      // Login with saved credentials
      await ref.read(authServiceProvider).login(
        email: credentials['email']!,
        password: credentials['password']!,
      );

      if (!mounted) return;
      context.go('/');

    } on BiometricException catch (e) {
      _showError(e.message);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Biometric login failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===================== EMAIL LOGIN =====================

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save credentials for biometric if enabled
      if (_rememberMe && _biometricAvailable) {
        await _promptBiometricSetup();
      }

      if (!mounted) return;
      context.go('/');
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promptBiometricSetup() async {
    try {
      final biometricService = ref.read(biometricServiceProvider);
      final isEnabled = await biometricService.isBiometricLoginEnabled();

      if (isEnabled) return;

      // Show dialog to enable biometric
      if (!mounted) return;

      final enable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enable $_biometricType?'),
          content: Text(
            'Would you like to use $_biometricType to login faster next time?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (enable == true) {
        await biometricService.saveCredentialsForBiometric(
          _emailController.text.trim(),
          _passwordController.text,
        );
        await biometricService.enableBiometricLogin();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType login enabled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail - biometric is optional
    }
  }

  // ===================== SOCIAL LOGIN =====================
// Replace your _handleGoogleSignIn method with this fixed version

  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;

    setState(() => _isGoogleLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();

      // ✅ CRITICAL: Wait longer for storage operations to complete
      // FlutterSecureStorage writes are async and may take longer on Android
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // ✅ Verify tokens with retry logic
      String? token;
      int retries = 3;

      while (retries > 0 && token == null) {
        token = await authService.getBackendToken();
        if (token == null) {
          print('⚠️ Token not available yet, retrying... ($retries attempts left)');
          await Future.delayed(const Duration(milliseconds: 200));
          retries--;
        }
      }

      if (token == null) {
        throw AuthException('Authentication completed but tokens not available');
      }

      print('✅ Token verified: ${token.substring(0, 30)}...');

      if (!mounted) return;

      // ✅ Navigate based on user type
      if (result.isNewUser) {
        _showWelcomeDialog();
      } else {
        context.go('/');
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      print('❌ Google sign-in error: $e');
      if (mounted) _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

// Apply the same fix to GitHub and Microsoft handlers
  Future<void> _handleGithubSignIn() async {
    if (!mounted) return;
    setState(() => _isGithubLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGithub();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Verify tokens with retry
      String? token;
      int retries = 3;

      while (retries > 0 && token == null) {
        token = await authService.getBackendToken();
        if (token == null) {
          await Future.delayed(const Duration(milliseconds: 200));
          retries--;
        }
      }

      if (token == null) {
        throw AuthException('Authentication completed but tokens not available');
      }

      if (!mounted) return;

      if (result.isNewUser) {
        _showWelcomeDialog();
      } else {
        context.go('/');
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('GitHub sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isGithubLoading = false);
    }
  }

  Future<void> _handleMicrosoftSignIn() async {
    if (!mounted) return;
    setState(() => _isMicrosoftLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithMicrosoft();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Verify tokens with retry
      String? token;
      int retries = 3;

      while (retries > 0 && token == null) {
        token = await authService.getBackendToken();
        if (token == null) {
          await Future.delayed(const Duration(milliseconds: 200));
          retries--;
        }
      }

      if (token == null) {
        throw AuthException('Authentication completed but tokens not available');
      }

      if (!mounted) return;

      if (result.isNewUser) {
        _showWelcomeDialog();
      } else {
        context.go('/');
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Microsoft sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isMicrosoftLoading = false);
    }
  }

  // Add these handler methods:

  // ===================== UI HELPERS =====================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Welcome! 🎉'),
        content: const Text('Your account has been created successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/');
            },
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (_) => const _ForgotPasswordDialog(),
    );
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.work_outline,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 32),

                // 🆕 BIOMETRIC LOGIN BUTTON (if available and enabled)
                if (_biometricAvailable && _biometricEnabled)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      icon: Icon(
                        _biometricType == 'Face ID'
                            ? Icons.face
                            : Icons.fingerprint,
                      ),
                      label: Text('Login with $_biometricType'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                // Divider if biometric is shown
                if (_biometricAvailable && _biometricEnabled) ...[
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'your@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Remember me & Forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🆕 Remember me checkbox (for biometric)
                    if (_biometricAvailable)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                          ),
                          Text(
                            'Remember me',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),

                    TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailLogin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),


// ... inside your Row widget
                // ... inside your Column widget
                const SizedBox(height: 24),

// Social Login Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Google
                    _SocialButton(
                      icon: FontAwesomeIcons.google,
                      label: 'Google',
                      color: const Color(0xFFDB4437),
                      isLoading: _isGoogleLoading,
                      onPressed: _handleGoogleSignIn,
                    ),
                    // GitHub
                    _SocialButton(
                      icon: FontAwesomeIcons.github,
                      label: 'GitHub',
                      color: const Color(0xFF181717),
                      isLoading: _isGithubLoading,
                      onPressed: _handleGithubSignIn,
                    ),
                    // X (Twitter)
                    // Microsoft
                    _SocialButton(
                      icon: FontAwesomeIcons.microsoft,
                      label: 'Microsoft',
                      color: const Color(0xFF00A4EF),
                      isLoading: _isMicrosoftLoading,
                      onPressed: _handleMicrosoftSignIn,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
// ... rest of the Sign Up Row
                const SizedBox(height: 32),

                // Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () => context.go('/auth/register'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SOCIAL BUTTON WIDGET
// ============================================================================

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
                : FaIcon(icon, color: color, size: 24), // Use FaIcon for brand logos
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FORGOT PASSWORD DIALOG
// ============================================================================

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  const _ForgotPasswordDialog();

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authServiceProvider)
          .sendPasswordReset(_emailController.text.trim());

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address to receive a password reset link.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetEmail,
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Send Reset Link'),
        ),
      ],
    );
  }
}