import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/logger.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

// Replace the _initialize method in your splash_screen.dart

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
          throw e;
        }
      } catch (e) {
        // Unexpected error
        debugPrint('❌ [Splash] Unexpected error: $e');
        throw e;
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
        decoration: const BoxDecoration(color: Colors.white),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Hero(
                tag: 'app_icon',
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.work,
                        size: 80,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // App Name
              const Text(
                'JobConnect',
                style: TextStyle(
                  color: Color(0xFF0D47A1),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Tagline
              Text(
                'Connecting Talent with Opportunity',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 60),

              // Loading Indicator
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
              ),

              const SizedBox(height: 16),

              // Loading text
              Text(
                'Loading your profile...',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}