import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/account_repository.dart';
import '../../../../core/services/feature_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class LegalAcceptancePage extends ConsumerStatefulWidget {
  const LegalAcceptancePage({super.key});

  @override
  ConsumerState<LegalAcceptancePage> createState() => _LegalAcceptancePageState();
}

class _LegalAcceptancePageState extends ConsumerState<LegalAcceptancePage> {
  bool _tosAccepted = false;
  bool _privacyAccepted = false;
  bool _submitting = false;

  Future<void> _accept(String tosVersion, String privacyVersion) async {
    if (!_tosAccepted || !_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept both Terms of Service and Privacy Policy'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(accountRepositoryProvider);
      await repo.acceptLegal(tosVersion: tosVersion, privacyVersion: privacyVersion);
      ref.invalidate(legalStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Terms accepted'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final legalAsync = ref.watch(legalStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Terms & Privacy'),
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
      ),
      body: legalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (data) {
          final currentVersions = data['currentVersions'] ?? {};
          final tosVersion = currentVersions['tosVersion'] ?? '1.0';
          final privacyVersion = currentVersions['privacyVersion'] ?? '1.0';
          final needsAcceptance = data['needsAcceptance'] ?? false;

          if (!needsAcceptance) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, size: 64, color: AppColors.success),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('All legal terms are up to date', style: TextStyle(fontSize: 18, color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedLg,
                  ),
                  child: const Icon(Icons.gavel, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Updated Terms',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'We\'ve updated our Terms of Service and Privacy Policy. Please review and accept to continue using HireNest.',
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _tosAccepted,
                        onChanged: (v) => setState(() => _tosAccepted = v ?? false),
                        title: Text('I accept the Terms of Service (v$tosVersion)', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: TextButton(
                          onPressed: () => context.push('/terms-of-service'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, 
                            alignment: Alignment.centerLeft,
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text('Read Terms of Service'),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      ),
                      const Divider(height: 1, indent: AppSpacing.xl, endIndent: AppSpacing.xl),
                      CheckboxListTile(
                        value: _privacyAccepted,
                        onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                        title: Text('I accept the Privacy Policy (v$privacyVersion)', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: TextButton(
                          onPressed: () => context.push('/privacy-policy'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, 
                            alignment: Alignment.centerLeft,
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text('Read Privacy Policy'),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_tosAccepted && _privacyAccepted && !_submitting)
                        ? () => _accept(tosVersion, privacyVersion)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                      disabledBackgroundColor: AppColors.grey400,
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)
                          )
                        : const Text('Accept & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
