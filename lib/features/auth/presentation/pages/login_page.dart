// ============================================================================
// LOGIN PAGE WITH BIOMETRIC AUTHENTICATION
// lib/features/auth/presentation/pages/login_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../profile/presentation/providers/balance_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../marketplace/presentation/providers/paginated_products_notifier.dart';
import '../../../marketplace/presentation/providers/my_products_provider.dart';
import '../../../marketplace/presentation/providers/order_details_provider.dart';
import '../../../applications/presentation/providers/applications_provider.dart' as app_providers;
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../providers/auth_provider.dart';

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
  // POST-LOGIN STATE REFRESH
  // ==========================================================================

  void _refreshStateAfterLogin() {
    debugPrint('🔄 [Login] Refreshing all user state providers...');
    
    // Auth & User State
    ref.invalidate(currentUserProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(profileStatsProvider);
    ref.invalidate(balanceProvider);
    ref.invalidate(backendTokenProvider);
    
    // Core App State
    ref.invalidate(jobsProvider);
    ref.invalidate(paginatedProductsProvider);
    ref.invalidate(myProductsProvider);
    ref.invalidate(myProductsStatsProvider);
    ref.invalidate(myOrdersProvider);
    ref.invalidate(mySalesProvider);

    // Applications Handlers — invalidate role FIRST so apps use new role
    ref.invalidate(app_providers.userRoleProvider);
    ref.invalidate(app_providers.myApplicationsProvider);
    ref.invalidate(app_providers.applicationStatsProvider);
    ref.invalidate(app_providers.applicationActionsProvider);

    debugPrint('✅ [Login] State providers invalidated');
  }

  // ==========================================================================
  // BIOMETRIC CHECK
  // ==========================================================================

  Future<void> _checkBiometric() async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final biometricService = ref.read(biometricServiceProvider);
      await biometricService.debugStorageContents();

      final available = await biometricService.isBiometricAvailable();
      if (!available) return;

      final types = await biometricService.getAvailableBiometrics();
      final typeName = biometricService.getTypeName(types);

      final enabled = await biometricService.isBiometricLoginEnabled();
      final hasCreds = await biometricService.hasSavedCredentials();

      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _biometricEnabled = enabled && hasCreds;
          _biometricType = typeName;
        });
      }

      if (enabled && hasCreds && mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          await _handleBiometricLogin();
        }
      }
    } catch (e) {
      AppLogger.error('Biometric init error', error: e);
    }
  }

  // ==========================================================================
  // BIOMETRIC LOGIN
  // ==========================================================================

  Future<void> _handleBiometricLogin() async {
    try {
      final biometricService = ref.read(biometricServiceProvider);

      final hasCreds = await biometricService.hasSavedCredentials();
      if (!hasCreds) {
        _showError('No saved credentials found. Please login with email/password first.');
        return;
      }

      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to login to HireNest',
      );
      if (!authenticated) return;

      final credentials = await biometricService.getSavedCredentials();
      if (credentials == null) {
        _showError('No saved credentials found. Please login with email/password first.');
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = true);

      await ref.read(authServiceProvider).login(
        email: credentials['email']!,
        password: credentials['password']!,
      );

      if (!mounted) return;
      _refreshStateAfterLogin();
      context.go('/');
    } on BiometricException catch (e) {
      if (mounted) _showError(e.message);
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Biometric login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================================================
  // EMAIL LOGIN
  // ==========================================================================

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (_rememberMe && _biometricAvailable) {
        await _promptBiometricSetup();
      }

      if (!mounted) return;
      _refreshStateAfterLogin();
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
      if (!mounted) return;

      final enable = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enable $_biometricType?'),
          content: Text('Would you like to use $_biometricType to login faster next time?'),
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
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Biometric setup error: $e');
    }
  }

  // ==========================================================================
  // SOCIAL LOGIN
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
          await Future.delayed(const Duration(milliseconds: 200));
          retries--;
        }
      }
      if (token == null) throw AuthException('Authentication completed but tokens not available');

      if (!mounted) return;
      if (result.isNewUser) {
        _showWelcomeDialog();
      } else {
        _refreshStateAfterLogin();
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
      if (token == null) throw AuthException('Authentication completed but tokens not available');

      if (!mounted) return;
      if (result.isNewUser) {
        _showWelcomeDialog();
      } else {
        _refreshStateAfterLogin();
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
      if (token == null) throw AuthException('Authentication completed but tokens not available');

      if (!mounted) return;
      if (result.isNewUser) {
        _showWelcomeDialog();
      } else {
        _refreshStateAfterLogin();
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
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
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
  // BUILD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.surfaceDark]
                : [AppColors.primary.withValues(alpha: 0.05), AppColors.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hero Logo
                      Hero(
                        tag: 'app_icon',
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.work_outline,
                                  size: 60,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                          color: isDark ? AppColors.textMutedLight : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Card for Form
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: AppSpacing.roundedXl,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (_biometricAvailable && _biometricEnabled)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _handleBiometricLogin,
                                  icon: Icon(
                                    _biometricType == 'Face ID'
                                        ? Icons.face
                                        : Icons.fingerprint,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    'Login with $_biometricType',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppSpacing.roundedLg,
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),

                            if (_biometricAvailable && _biometricEnabled) ...[
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                    child: Text(
                                      'OR',
                                      style: AppTextStyles.textTheme.labelMedium?.copyWith(
                                        color: isDark ? AppColors.textMutedLight : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTextStyles.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'your@email.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedLg,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your email';
                                if (!value.contains('@')) return 'Please enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: AppTextStyles.textTheme.bodyLarge,
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
                                border: OutlineInputBorder(
                                  borderRadius: AppSpacing.roundedLg,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your password';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_biometricAvailable)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (value) {
                                          setState(() => _rememberMe = value ?? false);
                                        },
                                      ),
                                      Text(
                                        'Remember me',
                                        style: AppTextStyles.textTheme.bodyMedium,
                                      ),
                                    ],
                                  )
                                else
                                  const SizedBox.shrink(),
                                TextButton(
                                  onPressed: _handleForgotPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleEmailLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppSpacing.roundedLg,
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.white,
                                ),
                              )
                                  : Text(
                                'Sign In',
                                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: AppTextStyles.textTheme.labelMedium?.copyWith(
                                color: isDark ? AppColors.textMutedLight : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton(
                            icon: FontAwesomeIcons.google,
                            color: AppColors.google,
                            isLoading: _isGoogleLoading,
                            onPressed: _handleGoogleSignIn,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          _SocialButton(
                            icon: FontAwesomeIcons.github,
                            color: AppColors.github,
                            isLoading: _isGithubLoading,
                            onPressed: _handleGithubSignIn,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          _SocialButton(
                            icon: FontAwesomeIcons.microsoft,
                            color: AppColors.microsoft,
                            isLoading: _isMicrosoftLoading,
                            onPressed: _handleMicrosoftSignIn,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textMutedLight : AppColors.textSecondaryLight,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/auth/register'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
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
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: AppSpacing.roundedLg,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
          borderRadius: AppSpacing.roundedLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: color,
            ),
          )
              : FaIcon(icon, color: color, size: 28),
        ),
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
      await ref.read(authServiceProvider).sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(AppSpacing.lg),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedXl,
      ),
      title: Text('Reset Password', style: AppTextStyles.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address to receive a password reset link.',
              style: AppTextStyles.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.roundedLg,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!value.contains('@')) return 'Please enter a valid email';
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
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.roundedLg,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
              : const Text('Send Reset Link', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}