import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttachment;
  final ValueChanged<String>? onChanged;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: AppSpacing.bottomNavShadow,
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (onAttachment != null)
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: onAttachment,
                color: AppColors.textSecondaryLight,
              ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMutedLight,
                      ),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedFull,
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedFull,
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppSpacing.roundedFull,
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimaryLight,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: AppColors.white),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}