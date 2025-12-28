// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize logger FIRST - this is critical!
    AppLogger.init();
    AppLogger.info('Starting JobConnect application...');

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase initialized successfully');

    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Use print as fallback if logger isn't ready
    print('Error during app initialization: $e');
    print('StackTrace: $stackTrace');

    // Try to log with AppLogger if possible
    try {
      AppLogger.error('App initialization failed', error: e, stackTrace: stackTrace);
    } catch (_) {
      // Logger not available, already printed above
    }
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'JobConnect',
      debugShowCheckedModeBanner: false,
      // ✅ FORCE WHITE THEME
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
