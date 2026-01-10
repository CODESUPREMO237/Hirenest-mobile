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

// ✅ CRITICAL: Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('Handling background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Notification: ${message.notification?.title}');
}

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

    // ✅ Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    AppLogger.info('Background message handler registered');

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