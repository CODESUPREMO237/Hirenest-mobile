// ============================================================================
// VERIFICATION PAGE — Submit & View Verification Badges
// lib/features/profile/presentation/pages/verification_page.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/account_repository.dart';
import '../../../../core/services/feature_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key});

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  final _typeOptions = ['identity', 'skill', 'education', 'employment'];
  String _selectedType = 'identity';
  final _labelController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submitting = false;

  static const _typeLabels = {
    'identity': 'Identity Verification',
    'skill': 'Skill Verification',
    'education': 'Education Verification',
    'employment': 'Employment Verification',
  };

  static const _typeIcons = {
    'identity': Icons.badge_rounded,
    'skill': Icons.construction_rounded,
    'education': Icons.school_rounded,
    'employment': Icons.work_rounded,
  };

  Future<void> _submit() async {
    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a label')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(accountRepositoryProvider);
      await repo.submitVerification(
        type: _selectedType,
        label: _labelController.text.trim(),
        documents: [], // In production: upload docs via image picker
        userNote: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );
      ref.invalidate(myVerificationsProvider);
      _labelController.clear();
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Verification submitted for review'), backgroundColor: AppColors.success),
        );
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

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final verificationsAsync = ref.watch(myVerificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Verification Badges'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppSpacing.roundedLg,
              boxShadow: AppSpacing.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request Verification', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Verification Type', 
                    border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg, borderSide: BorderSide.none),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                  items: _typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(_typeLabels[t]!))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: 'Label (e.g. "Flutter Developer")',
                    border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg, borderSide: BorderSide.none),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes (optional)', 
                    border: OutlineInputBorder(borderRadius: AppSpacing.roundedLg, borderSide: BorderSide.none),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                        : const Text('Submit for Review', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),
          Text('My Verifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
          const SizedBox(height: AppSpacing.sm),

          verificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Text('Error: $e'),
            data: (verifications) {
              if (verifications.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified_outlined, size: 64, color: AppColors.textMutedLight),
                        const SizedBox(height: AppSpacing.md),
                        Text('No verification requests yet.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMutedLight)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: verifications.map<Widget>((v) {
                  final type = v['type'] ?? '';
                  final status = v['status'] ?? 'pending';
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: AppSpacing.roundedLg,
                      boxShadow: AppSpacing.cardShadow,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_typeIcons[type] ?? Icons.verified_rounded, color: _statusColor(status)),
                      ),
                      title: Text(v['label'] ?? type, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('${_typeLabels[type] ?? type}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withValues(alpha: 0.15),
                          borderRadius: AppSpacing.roundedFull,
                        ),
                        child: Text(
                          status.toString().toUpperCase(), 
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _statusColor(status), fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
