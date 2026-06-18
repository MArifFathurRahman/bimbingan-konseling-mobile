import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/constants/app_textstyle.dart';
import '../models/chat_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * (isMine ? 0.75 : 0.85),
              minWidth: 60,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMine
                  ? AppColors.primary
                  : AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMine ? 20 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 20),
              ),
              boxShadow: isMine
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              message.text,
              style: AppTextStyle.bodyMd.copyWith(
                color: isMine ? AppColors.onPrimary : AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: AppTextStyle.labelMd.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class TypingIndicator extends StatelessWidget {
  final String name;

  const TypingIndicator({
    super.key,
    this.name = 'Konselor',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: Duration(milliseconds: 600 + index * 200),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.outline,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          Text(
            '$name is typing...',
            style: AppTextStyle.labelMd.copyWith(
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class EncryptionNotice extends StatelessWidget {
  const EncryptionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 14,
              color: AppColors.outline,
            ),
            const SizedBox(width: 6),
            Text(
              'Messages are end-to-end encrypted.',
              style: AppTextStyle.labelLg.copyWith(
                color: AppColors.outline,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
