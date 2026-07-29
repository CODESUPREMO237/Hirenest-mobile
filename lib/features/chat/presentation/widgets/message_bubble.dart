import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isMyMessage = message.isMyMessage;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment:
              isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMyMessage) ...[
              const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceLight,
                child: Icon(Icons.person, size: 14, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isMyMessage ? AppColors.primary : AppColors.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppSpacing.radiusLg),
                    topRight: const Radius.circular(AppSpacing.radiusLg),
                    bottomLeft: Radius.circular(isMyMessage ? AppSpacing.radiusLg : AppSpacing.radiusSm),
                    bottomRight: Radius.circular(isMyMessage ? AppSpacing.radiusSm : AppSpacing.radiusLg),
                  ),
                  border: isMyMessage ? null : Border.all(color: AppColors.borderLight),
                  boxShadow: isMyMessage ? null : AppSpacing.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectionArea(
                      child: _buildMessageContent(
                        context,
                        message.content,
                        isMyMessage,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isMyMessage
                                    ? AppColors.white.withValues(alpha: 0.8)
                                    : AppColors.textMutedLight,
                              ),
                        ),
                        if (isMyMessage) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isMyMessage) const SizedBox(width: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (message.read) {
      return const Icon(
        Icons.done_all,
        size: 14,
        color: AppColors.white,
      );
    }

    return Icon(
      Icons.done,
      size: 14,
      color: AppColors.white.withValues(alpha: 0.7),
    );
  }

  Widget _buildMessageContent(BuildContext context, String text, bool isMe) {
    final List<String> parts = text.split('**');

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isMe ? AppColors.white : AppColors.textPrimaryLight,
        );

    if (parts.length == 1) {
      return Text(
        text,
        style: textStyle,
      );
    }

    return RichText(
      text: TextSpan(
        style: textStyle,
        children: List.generate(parts.length, (index) {
          final bool isBold = index % 2 != 0;
          return TextSpan(
            text: parts[index],
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              decoration: isBold ? TextDecoration.underline : null,
              backgroundColor: isBold
                  ? (isMe
                      ? AppColors.white.withValues(alpha: 0.2)
                      : AppColors.textMutedLight.withValues(alpha: 0.1))
                  : null,
            ),
          );
        }),
      ),
    );
  }
}