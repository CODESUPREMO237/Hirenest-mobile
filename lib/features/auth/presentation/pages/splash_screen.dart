import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/logger.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _nameFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initialize();
  }
  
  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.533, curve: AppAnimations.enter), // 800ms of 1500ms
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.533, curve: Curves.easeIn),
      ),
    );

    _nameFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.533, 0.8, curve: Curves.easeIn), // starts after logo
      ),
    );

    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.7, 1.0, curve: AppAnimations.enter),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Show splash for minimum time
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authService = ref.read(authServiceProvider);

    try {
      debugPrint('🚀 [Splash] Initializing app...');

      // ✅ RETRY LOGIC: Check authentication multiple times to handle race conditions
      bool isAuth = false;
      int retries = 0;
      const maxRetries = 3;

      while (retries < maxRetries && !isAuth) {
        isAuth = await authService.isAuthenticated();

        if (!isAuth && retries < maxRetries - 1) {
          debugPrint('⏳ [Splash] Not authenticated yet, waiting... (attempt ${retries + 1}/$maxRetries)');
          await Future.delayed(Duration(milliseconds: 500 * (retries + 1)));
          retries++;
        } else {
          break;
        }
      }

      if (!isAuth) {
        debugPrint('❌ [Splash] Not authenticated after $maxRetries attempts, going to login');
        if (mounted) context.go('/auth/login');
        return;
      }

      debugPrint('✅ [Splash] User is authenticated');

      // ✅ Step 2: Try to get cached user data first (instant)
      final cachedUser = await authService.getCachedUserData();

      if (cachedUser != null) {
        debugPrint('✅ [Splash] Using cached user data for: ${cachedUser['email']}');
        _navigateBasedOnRole(cachedUser);
        return;
      }

      // ✅ Step 3: No cache found, fetch from server with retry
      debugPrint('ℹ️ [Splash] No cached data, fetching from server...');
      await _fetchAndNavigate(authService);

    } catch (e, stackTrace) {
      debugPrint('❌ [Splash] Error during initialization: $e');
      AppLogger.error('Splash initialization failed', error: e, stackTrace: stackTrace);

      // Clear auth data and go to login
      try {
        await authService.clearAuthData();
      } catch (clearError) {
        debugPrint('⚠️ [Splash] Error clearing auth data: $clearError');
      }

      if (mounted) context.go('/auth/login');
    }
  }

  /// Fetch profile from server with retry logic
  Future<void> _fetchAndNavigate(AuthService authService) async {
    int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        debugPrint('📡 [Splash] Fetching profile (attempt ${retryCount + 1}/$maxRetries)...');

        final user = await authService.fetchProfile();

        debugPrint('✅ [Splash] Profile fetched successfully');
        _navigateBasedOnRole(user);
        return;

      } on AuthException catch (e) {
        if (e.message.contains('User not found') && retryCount < maxRetries - 1) {
          // User might still be creating in backend, retry with exponential backoff
          final delayMs = 500 * (retryCount + 1); // 500ms, 1000ms, 1500ms
          debugPrint('⏳ [Splash] User not found, retrying in ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
          retryCount++;
        } else {
          // Max retries reached or different error
          debugPrint('❌ [Splash] Auth error: ${e.message}');
          rethrow;
        }
      } catch (e) {
        // Unexpected error
        debugPrint('❌ [Splash] Unexpected error: $e');
        rethrow;
      }
    }

    // If we get here, all retries failed
    throw AuthException('Could not fetch user profile after $maxRetries attempts');
  }

  /// Navigate based on user role
  void _navigateBasedOnRole(Map<String, dynamic> user) {
    if (!mounted) return;

    final role = user['role'] as String?;
    final email = user['email'] as String?;

    debugPrint('🧭 [Splash] Navigating user: $email (role: $role)');

    // Navigate to main page - MainPage will handle role-based UI
    switch (role) {
      case 'jobseeker':
      case 'employer':
        context.go('/');
        break;
      default:
        debugPrint('⚠️ [Splash] Unknown role: $role, going to onboarding');
        context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.primaryDark.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Hero(
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
                                spreadRadius: 8,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.work,
                                size: 64,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // App Name
                  FadeTransition(
                    opacity: _nameFade,
                    child: Text(
                      'HireNest',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ) ?? const TextStyle(
                        color: AppColors.primary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Tagline
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Connecting Talent with Opportunity',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ) ?? const TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Modern Loading Indicator (thin linear progress bar)
                  FadeTransition(
                    opacity: _nameFade,
                    child: SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: AppSpacing.roundedFull,
                        child: const LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}