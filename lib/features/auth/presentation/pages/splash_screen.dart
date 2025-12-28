import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';

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

  Future<void> _initialize() async {
    // Wait for splash animation (gives user time to see your logo)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authService = ref.read(authServiceProvider);

    try {
      final token = await authService.getIdToken();
      if (token != null) {
        await authService.fetchProfile();
        if (mounted) context.go('/');
      } else {
        if (mounted) context.go('/auth/login');
      }
    } catch (e) {
      if (mounted) context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using a white background to match your logo's clean aesthetic
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.white),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- YOUR LOGO ---
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
                      'assets/images/app_icon.png', // Ensure this path matches your folder
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.work,
                          size: 80,
                          color: Colors.blue
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- APP NAME ---
              const Text(
                'JobConnect',
                style: TextStyle(
                  color: Color(0xFF0D47A1), // Deep Blue to match your logo
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // --- TAGLINE ---
              Text(
                'Connecting Talent with Opportunity',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 60),

              // --- LOADING INDICATOR ---
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