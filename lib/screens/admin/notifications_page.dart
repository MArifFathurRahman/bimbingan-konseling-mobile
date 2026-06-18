import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../models/notification_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import 'counseling_requests_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.notifications
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Gagal memuat notifikasi',
                        style: AppTextStyle.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const ShimmerList(itemCount: 4);
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'Belum ada notifikasi',
                      subtitle: 'Notifikasi akan muncul di sini',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.marginMobile,
                      AppSizes.stackMd,
                      AppSizes.marginMobile,
                      100,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final item = NotificationItem.fromSnapshot(docs[index]);
                      return _buildNotificationCard(item, docs[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.marginMobile),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text(
            'Notifikasi',
            style: AppTextStyle.titleLg.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, QueryDocumentSnapshot doc) {
    final isUnread = !item.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            doc.reference.update({'isRead': true});
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CounselingRequestsPage(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSizes.cardPadding),
          decoration: BoxDecoration(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.04)
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSizes.radius2xl),
            border: isUnread
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.1))
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor.withValues(alpha: 0.06),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(item.priority),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyle.titleLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityBadge(item.priority),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time, size: 12, color: AppColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(item.createdAt),
                          style: AppTextStyle.labelMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String priority) {
    Color bg;
    Color fg;
    switch (priority) {
      case 'tinggi':
        bg = Colors.red.withValues(alpha: 0.1);
        fg = Colors.red;
      case 'sedang':
        bg = Colors.orange.withValues(alpha: 0.1);
        fg = Colors.orange;
      default:
        bg = Colors.green.withValues(alpha: 0.1);
        fg = Colors.green;
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.psychology, color: fg, size: 22),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;
    switch (priority) {
      case 'tinggi':
        color = Colors.red;
        label = 'TINGGI';
      case 'sedang':
        color = Colors.orange;
        label = 'SEDANG';
      default:
        color = Colors.green;
        label = 'RENDAH';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyle.labelMd.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
