// ============================================================================
// LOGIN PAGE WITH BIOMETRIC AUTHENTICATION + DEBUG
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

  // ==========================================================================
  // BIOMETRIC CHECK WITH DEBUG
  // ==========================================================================

  Future<void> _checkBiometric() async {
    print('');
    print('🔐 ========================================');
    print('🔐 BIOMETRIC CHECK STARTED');
    print('🔐 ========================================');

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final biometricService = ref.read(biometricServiceProvider);

      // Debug storage first
      await biometricService.debugStorageContents();

      // Step 1: Check hardware
      print('🔐 Step 1: Checking hardware availability...');
      final available = await biometricService.isBiometricAvailable();
      print('   Result: $available');

      if (!available) {
        print('🔐 ❌ Hardware not available - stopping check');
        print('🔐 ========================================');
        print('');
        return;
      }

      // Step 2: Get biometric types
      print('🔐 Step 2: Getting biometric types...');
      final types = await biometricService.getAvailableBiometrics();
      final typeName = biometricService.getTypeName(types);
      print('   Types: $types');
      print('   Name: $typeName');

      // Step 3: Check if enabled
      print('🔐 Step 3: Checking if biometric login is enabled...');
      final enabled = await biometricService.isBiometricLoginEnabled();
      print('   Result: $enabled');

      // Step 4: Check if credentials saved
      print('🔐 Step 4: Checking for saved credentials...');
      final hasCreds = await biometricService.hasSavedCredentials();
      print('   Result: $hasCreds');

      // Step 5: Update UI
      print('🔐 Step 5: Updating UI state...');
      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _biometricEnabled = enabled && hasCreds;
          _biometricType = typeName;
        });

        print('   UI State:');
        print('   - Available: $_biometricAvailable');
        print('   - Enabled: $_biometricEnabled');
        print('   - Type: $_biometricType');
      }

      // Step 6: Auto-prompt decision
      print('🔐 Step 6: Evaluating auto-prompt...');
      print('   - Enabled: $enabled');
      print('   - Has credentials: $hasCreds');
      print('   - Mounted: $mounted');

      if (enabled && hasCreds && mounted) {
        print('🔐 ✅ All conditions met - scheduling auto-prompt');

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          print('🔐 🚀 SHOWING AUTO-PROMPT NOW');
          await _handleBiometricLogin();
        } else {
          print('🔐 ⚠️ Widget unmounted - cancelling auto-prompt');
        }
      } else {
        print('🔐 ❌ Auto-prompt skipped - conditions not met');
      }

      print('🔐 ========================================');
      print('🔐 BIOMETRIC CHECK COMPLETED');
      print('🔐 ========================================');
      print('');

    } catch (e, stackTrace) {
      print('🔐 ❌ ERROR DURING BIOMETRIC CHECK: $e');
      print('Stack trace: $stackTrace');
      print('🔐 ========================================');
      print('');
      AppLogger.error('Biometric init error', error: e);
    }
  }

  // ==========================================================================
  // BIOMETRIC LOGIN WITH DEBUG
  // ==========================================================================

  Future<void> _handleBiometricLogin() async {
    print('');
    print('🔓 ========================================');
    print('🔓 BIOMETRIC LOGIN STARTED');
    print('🔓 ========================================');

    try {
      final biometricService = ref.read(biometricServiceProvider);

      // Step 1: Verify credentials exist
      print('🔓 Step 1: Verifying saved credentials...');
      final hasCreds = await biometricService.hasSavedCredentials();
      print('   Result: $hasCreds');

      if (!hasCreds) {
        print('🔓 ❌ No credentials - aborting');
        print('🔓 ========================================');
        print('');
        _showError('No saved credentials found. Please login with email/password first.');
        return;
      }

      // Step 2: Authenticate
      print('🔓 Step 2: Showing biometric prompt...');
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to login to JobConnect',
      );
      print('   Result: $authenticated');

      if (!authenticated) {
        print('🔓 ⚠️ Authentication cancelled or failed');
        print('🔓 ========================================');
        print('');
        return;
      }

      // Step 3: Get credentials
      print('🔓 Step 3: Retrieving credentials...');
      final credentials = await biometricService.getSavedCredentials();
      print('   Email: ${credentials?['email']}');
      print('   Password: ${credentials?['password'] != null ? "Present (${credentials!['password']!.length} chars)" : "Missing"}');

      if (credentials == null) {
        print('🔓 ❌ Credentials retrieval failed');
        print('🔓 ========================================');
        print('');
        _showError('No saved credentials found. Please login with email/password first.');
        return;
      }

      if (!mounted) {
        print('🔓 ⚠️ Widget unmounted - aborting');
        print('🔓 ========================================');
        print('');
        return;
      }

      setState(() => _isLoading = true);

      // Step 4: Login
      print('🔓 Step 4: Logging in...');
      await ref.read(authServiceProvider).login(
        email: credentials['email']!,
        password: credentials['password']!,
      );
      print('   ✅ Login successful');

      if (!mounted) return;

      // Step 5: Navigate
      print('🔓 Step 5: Navigating to home...');
      context.go('/');

      print('🔓 ========================================');
      print('🔓 BIOMETRIC LOGIN COMPLETED');
      print('🔓 ========================================');
      print('');

    } on BiometricException catch (e) {
      print('🔓 ❌ BiometricException: ${e.message}');
      print('🔓 ========================================');
      print('');
      if (mounted) _showError(e.message);
    } on AuthException catch (e) {
      print('🔓 ❌ AuthException: ${e.message}');
      print('🔓 ========================================');
      print('');
      if (mounted) _showError(e.message);
    } catch (e, stackTrace) {
      print('🔓 ❌ Unexpected error: $e');
      print('Stack trace: $stackTrace');
      print('🔓 ========================================');
      print('');
      if (mounted) _showError('Biometric login failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==========================================================================
  // EMAIL LOGIN
  // ==========================================================================

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('📧 Logging in with email: ${_emailController.text.trim()}');

      await ref.read(authServiceProvider).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('✅ Email login successful');

      // Save credentials for biometric if enabled
      if (_rememberMe && _biometricAvailable) {
        print('💾 Remember me checked - prompting for biometric setup');
        await _promptBiometricSetup();
      }

      if (!mounted) return;
      context.go('/');
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promptBiometricSetup() async {
    try {
      print('');
      print('💾 ========================================');
      print('💾 BIOMETRIC SETUP PROMPT');
      print('💾 ========================================');

      final biometricService = ref.read(biometricServiceProvider);
      final isEnabled = await biometricService.isBiometricLoginEnabled();

      print('💾 Already enabled: $isEnabled');

      if (isEnabled) {
        print('💾 Biometric already enabled - skipping prompt');
        print('💾 ========================================');
        print('');
        return;
      }

      if (!mounted) return;

      print('💾 Showing enable dialog...');

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

      print('💾 User choice: ${enable == true ? "Enable" : "Skip"}');

      if (enable == true) {
        print('💾 Saving credentials...');

        await biometricService.saveCredentialsForBiometric(
          _emailController.text.trim(),
          _passwordController.text,
        );

        print('💾 Enabling biometric login...');

        await biometricService.enableBiometricLogin();

        // Verify
        await biometricService.debugStorageContents();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType login enabled'),
              backgroundColor: Colors.green,
            ),
          );
        }

        print('✅ Biometric setup completed');
      }

      print('💾 ========================================');
      print('');
    } catch (e, stackTrace) {
      print('❌ Biometric setup error: $e');
      print('Stack trace: $stackTrace');
      print('💾 ========================================');
      print('');
    }
  }

  // ==========================================================================
  // SOCIAL LOGIN (with retry logic)
  // ==========================================================================

  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;

    setState(() => _isGoogleLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

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

      if (!mounted) return;

      if (result.isNewUser) {
        _showWelcomeDialog();
      } else {
        context.go('/');
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleGithubSignIn() async {
    if (!mounted) return;
    setState(() => _isGithubLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGithub();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

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

  // ==========================================================================
  // UI HELPERS
  // ==========================================================================

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

  // ==========================================================================
  // DEBUG WIDGET
  // ==========================================================================

  // Widget _buildDebugInfo() {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 16),
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.grey[100],
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: Colors.grey[300]!),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           '🔍 Debug Info',
  //           style: TextStyle(
  //             fontWeight: FontWeight.bold,
  //             fontSize: 12,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         _buildDebugRow('Hardware Available', _biometricAvailable),
  //         _buildDebugRow('Login Enabled', _biometricEnabled),
  //         Text(
  //           'Type: $_biometricType',
  //           style: const TextStyle(fontSize: 11),
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: ElevatedButton(
  //                 onPressed: () async {
  //                   final service = ref.read(biometricServiceProvider);
  //                   await service.debugStorageContents();
  //                   final hasCreds = await service.hasSavedCredentials();
  //                   final enabled = await service.isBiometricLoginEnabled();
  //
  //                   if (!mounted) return;
  //
  //                   showDialog(
  //                     context: context,
  //                     builder: (context) => AlertDialog(
  //                       title: const Text('Storage Check'),
  //                       content: Column(
  //                         mainAxisSize: MainAxisSize.min,
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text('Has Credentials: $hasCreds'),
  //                           Text('Is Enabled: $enabled'),
  //                         ],
  //                       ),
  //                       actions: [
  //                         TextButton(
  //                           onPressed: () => Navigator.pop(context),
  //                           child: const Text('OK'),
  //                         ),
  //                       ],
  //                     ),
  //                   );
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   padding: const EdgeInsets.symmetric(vertical: 8),
  //                 ),
  //                 child: const Text(
  //                   'Check Storage',
  //                   style: TextStyle(fontSize: 11),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             Expanded(
  //               child: ElevatedButton(
  //                 onPressed: _checkBiometric,
  //                 style: ElevatedButton.styleFrom(
  //                   padding: const EdgeInsets.symmetric(vertical: 8),
  //                 ),
  //                 child: const Text(
  //                   'Refresh',
  //                   style: TextStyle(fontSize: 11),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDebugRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          Text(
            value ? '✅ Yes' : '❌ No',
            style: TextStyle(
              fontSize: 11,
              color: value ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

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

                // DEBUG INFO
                // _buildDebugInfo(),

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

                // Biometric button
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

                // Divider
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

                // Email field
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

                // Password field
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

                // Remember me
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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

                // Login button
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

                // Social login
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SocialButton(
                      icon: FontAwesomeIcons.google,
                      label: 'Google',
                      color: const Color(0xFFDB4437),
                      isLoading: _isGoogleLoading,
                      onPressed: _handleGoogleSignIn,
                    ),
                    _SocialButton(
                      icon: FontAwesomeIcons.github,
                      label: 'GitHub',
                      color: const Color(0xFF181717),
                      isLoading: _isGithubLoading,
                      onPressed: _handleGithubSignIn,
                    ),
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

                // Sign up
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
        : FaIcon(icon, color: color, size: 24),
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