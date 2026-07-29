// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// ✅ CRITICAL: Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }
  
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Notification: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Initialize logger FIRST - this is critical!
    AppLogger.init();
    AppLogger.info('Starting HireNest application...');

    // Initialize Firebase
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        AppLogger.info('Firebase app already initialized');
      } else {
        rethrow;
      }
    }
    AppLogger.info('Firebase initialized successfully');

    // ✅ Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    AppLogger.info('Background message handler registered');

    // ✅ Initialize Sentry
    if (dotenv.env['SENTRY_DSN'] != null && dotenv.env['SENTRY_DSN']!.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = dotenv.env['SENTRY_DSN'];
          options.tracesSampleRate = 1.0; 
          options.environment = const String.fromEnvironment('ENV', defaultValue: 'development');
        },
        appRunner: () => runApp(
          const ProviderScope(
            child: MyApp(),
          ),
        ),
      );
    } else {
      runApp(
        const ProviderScope(
          child: MyApp(),
        ),
      );
    }
  } catch (e, stackTrace) {
    // Use print as fallback if logger isn't ready
    debugPrint('Error during app initialization: $e');
    debugPrint('StackTrace: $stackTrace');

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

    // ✅ Initialize notifications when app builds
    ref.listen(notificationServiceProvider, (previous, next) {
      // This ensures the service is created
    });

    // Initialize notification service
    Future.microtask(() async {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
    });

    return MaterialApp.router(
      title: 'HireNest',
      debugShowCheckedModeBanner: false,
      // ✅ FORCE WHITE THEME
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}