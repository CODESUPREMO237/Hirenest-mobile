// ============================================================================
// REGISTER PAGE
// lib/features/auth/presentation/pages/register_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/services/auth_service.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String _selectedRole = 'jobseeker';

  // Social login loading states
  bool _isGoogleLoading = false;
  bool _isGithubLoading = false;
  bool _isMicrosoftLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================================
  // SOCIAL LOGIN
  // ============================================================================

  Future<void> _handleSocialRegister(String provider) async {
    setState(() {
      if (provider == 'google') _isGoogleLoading = true;
      if (provider == 'github') _isGithubLoading = true;
      if (provider == 'microsoft') _isMicrosoftLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      if (provider == 'google') await authService.signInWithGoogle();
      if (provider == 'github') await authService.signInWithGithub();
      if (provider == 'microsoft') await authService.signInWithMicrosoft();

      if (mounted) context.go('/');
    } on AuthException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
          _isGithubLoading = false;
          _isMicrosoftLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================================
  // REGISTER
  // ============================================================================

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms & Conditions'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        profile: {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'displayName':
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          if (_phoneController.text.isNotEmpty)
            'phone': _phoneController.text.trim(),
        },
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
            title: Text('Success!', style: AppTextStyles.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            content: const Text(
              'Your account has been created successfully. Please check your email to verify your account.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go('/');
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.black,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Sign up to get started',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                          color: isDark ? AppColors.textMutedLight : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Card Wrapper
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Role Selection
                            Text(
                              'I am a...',
                              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _RoleCard(
                                    icon: Icons.person_search,
                                    label: 'Job Seeker',
                                    description: 'Find your dream job',
                                    isSelected: _selectedRole == 'jobseeker',
                                    onTap: () => setState(() => _selectedRole = 'jobseeker'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _RoleCard(
                                    icon: Icons.business,
                                    label: 'Employer',
                                    description: 'Hire great talent',
                                    isSelected: _selectedRole == 'employer',
                                    onTap: () => setState(() => _selectedRole = 'employer'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // First & Last Name
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      prefixIcon: const Icon(Icons.person_outline),
                                      border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg),
                                    ),
                                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      prefixIcon: const Icon(Icons.person_outline),
                                      border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg),
                                    ),
                                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'your@email.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your email';
                                if (!value.contains('@')) return 'Please enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone (Optional)',
                                hintText: '+237 XXX XXX XXX',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'At least 8 characters',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter a password';
                                if (value.length < 8) return 'Password must be at least 8 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please confirm your password';
                                if (value != _passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Terms
                            CheckboxListTile(
                              value: _agreedToTerms,
                              onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.primary,
                              title: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? AppColors.textMutedLight : AppColors.textSecondaryLight,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Register Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
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
                                'Create Account',
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

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Text(
                              'OR SIGN UP WITH',
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

                      // Social Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton(
                            icon: FontAwesomeIcons.google,
                            color: AppColors.google,
                            isLoading: _isGoogleLoading,
                            onPressed: () => _handleSocialRegister('google'),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          _SocialButton(
                            icon: FontAwesomeIcons.github,
                            color: AppColors.github,
                            isLoading: _isGithubLoading,
                            onPressed: () => _handleSocialRegister('github'),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          _SocialButton(
                            icon: FontAwesomeIcons.microsoft,
                            color: AppColors.microsoft,
                            isLoading: _isMicrosoftLoading,
                            onPressed: () => _handleSocialRegister('microsoft'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Sign In Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textMutedLight : AppColors.textSecondaryLight,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/auth/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text(
                              'Sign In',
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
  final VoidCallback onPressed;
  final bool isLoading;

  const _SocialButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
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
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
              : FaIcon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}

// ============================================================================
// ROLE CARD WIDGET
// ============================================================================

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedLg,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppSpacing.roundedLg,
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textMutedLight,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}