// ============================================================================
// Global Error Overlay
// lib/core/widgets/global_error_overlay.dart
//
// Full-screen white overlay that blocks the entire app (including bottom tabs)
// when a critical provider failure occurs. Only triggers for root-level
// connection failures on critical requests (e.g. currentUserProvider).
//
// Auth failures (401/invalid session) are handled separately by the
// ErrorInterceptor which clears session and redirects to login.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/global_error_provider.dart';
import '../theme/app_colors.dart';
import 'error_widget.dart';

class GlobalErrorOverlay extends ConsumerWidget {
  final Widget child;

  const GlobalErrorOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criticalError = ref.watch(globalCriticalErrorProvider);

    if (criticalError != null) {
      // Full white screen — hides bottom tabs and all content
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: CustomErrorWidget(
          message: criticalError.message,
          onRetry: () {
            // 1. Clear the critical error state
            ref.read(globalCriticalErrorProvider.notifier).state = null;
            // 2. Invoke the specific retry logic provided by the failed provider
            criticalError.onRetry();
          },
        ),
      );
    }

    return child;
  }
}
