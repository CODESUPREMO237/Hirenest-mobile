import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authService = ref.read(authServiceProvider);

    try {
      // ✅ Try to get token with retry logic (for race conditions)
      String? token;
      int retries = 5;

      while (retries > 0 && token == null) {
        token = await authService.getBackendToken();
        if (token == null) {
          debugPrint('⚠️ Token not found, retry ${6 - retries}/5');
          await Future.delayed(const Duration(milliseconds: 300));
          retries--;
        }
      }

      if (token != null) {
        debugPrint('✅ Token found: ${token.substring(0, 30)}...');

        // Check for cached user data
        final userData = await _storage.read(key: "userData");

        if (userData != null) {
          debugPrint('✅ User data cached, navigating to home');
          if (mounted) context.go('/');
          return;
        }

        // If no cached data, fetch it
        debugPrint('⚠️ No cached user data, fetching from server...');
        try {
          await authService.fetchProfile();
          debugPrint('✅ Profile fetched successfully');
          if (mounted) context.go('/');
        } catch (e) {
          debugPrint('❌ Profile fetch failed: $e');
          // Continue to login even if profile fetch fails
          // The app will fetch it later
          if (mounted) context.go('/');
        }
      } else {
        debugPrint('❌ No token after retries, navigating to login');
        if (mounted) context.go('/auth/login');
      }
    } catch (e) {
      debugPrint("❌ Splash Error: $e");

      // Force logout to clear bad session
      try {
        await authService.signOut();
      } catch (logoutError) {
        debugPrint("⚠️ Logout error: $logoutError");
      }

      if (mounted) context.go('/auth/login');
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
            ],
          ),
        ),
      ),
    );
  }
}