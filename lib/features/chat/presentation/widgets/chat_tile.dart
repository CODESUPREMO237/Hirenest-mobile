import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/chat_model.dart';
import 'online_status.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final participant = chat.participants.first;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.backgroundLight,
                  backgroundImage: participant.avatar != null
                      ? NetworkImage(participant.avatar!)
                      : null,
                  child: participant.avatar == null
                      ? Text(
                          participant.name.isNotEmpty
                              ? participant.name[0].toUpperCase()
                              : 'U',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        )
                      : null,
                ),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: OnlineStatus(isOnline: false, size: 14),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    participant.name.isNotEmpty ? participant.name : 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.lastMessage?.content ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: chat.unreadCount > 0
                              ? AppColors.textPrimaryLight
                              : AppColors.textSecondaryLight,
                          fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeago.format(chat.lastMessage?.timestamp ?? chat.updatedAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: chat.unreadCount > 0
                            ? AppColors.primary
                            : AppColors.textMutedLight,
                        fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
                if (chat.unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Text(
                      '${chat.unreadCount}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
