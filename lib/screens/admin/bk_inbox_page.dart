import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/utils/safe_display.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/profile_avatar.dart';
import '../student/counseling_chat_page.dart';

class BkInboxPage extends StatefulWidget {
  const BkInboxPage({super.key});

  @override
  State<BkInboxPage> createState() => _BkInboxPageState();
}

class _BkInboxPageState extends State<BkInboxPage> {
  int _currentNav = 0;

  Map<String, dynamic>? _safeData(QueryDocumentSnapshot doc) {
    final raw = doc.data();
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.marginMobile,
                  AppSizes.stackLg,
                  AppSizes.marginMobile,
                  100,
                ),
                children: [
                  Text(
                    'Pesan Siswa',
                    style: AppTextStyle.headlineLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Percakapan dengan siswa',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildConversationList(currentUserId),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationList(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.chats
          .where('participants', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('BkInboxPage error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Text(
                'Gagal memuat percakapan',
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child:
                CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final allDocs = snapshot.data!.docs.where((doc) {
          final data = _safeData(doc);
          if (data == null) return false;
          final participants = data['participants'];
          if (participants is! List) return false;
          return participants.length >= 2;
        }).toList();

        if (allDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Text(
                'Belum ada percakapan dengan siswa',
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        allDocs.sort((a, b) {
          final aData = _safeData(a);
          final bData = _safeData(b);
          if (aData == null || bData == null) return 0;
          final aTime = aData['updatedAt'];
          final bTime = bData['updatedAt'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        return Column(
          children: allDocs.map((doc) {
            final data = _safeData(doc);
            if (data == null) return const SizedBox.shrink();

            final participantsRaw = data['participants'];
            final participants = (participantsRaw is List)
                ? participantsRaw.whereType<String>().toList()
                : <String>[];
            if (participants.length < 2) return const SizedBox.shrink();

            final participantInfo =
                (data['participantInfo'] is Map)
                    ? (data['participantInfo'] as Map<String, dynamic>)
                    : null;

            final lastMessage =
                (data['lastMessage'] is Map)
                    ? (data['lastMessage'] as Map<String, dynamic>)
                    : null;

            final studentId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => participants.last);
            if (studentId.isEmpty) return const SizedBox.shrink();

            final studentInfo = (participantInfo?[studentId] is Map)
                ? (participantInfo![studentId] as Map<String, dynamic>)
                : null;
            final rawName = (studentInfo?['name'] as String?) ?? '';
            final studentName = safeDisplayName(rawName, 'Siswa');

            final lastMsgText =
                (lastMessage?['text'] as String?) ?? '';
            final lastTime =
                (data['updatedAt'] is Timestamp)
                    ? (data['updatedAt'] as Timestamp).toDate()
                    : null;

            return _buildConversationCard(
              studentId: studentId,
              studentName: studentName,
              lastMsg: lastMsgText,
              lastTime: lastTime,
            );
          }).toList(),
        );
      },
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
            'SafeSpace',
            style: AppTextStyle.titleLg.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryFixedDim),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard({
    required String studentId,
    required String studentName,
    required String lastMsg,
    required DateTime? lastTime,
  }) {
    final timeStr = lastTime != null
        ? '${lastTime.hour.toString().padLeft(2, '0')}:${lastTime.minute.toString().padLeft(2, '0')}'
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CounselingChatPage(
              counselorId: studentId,
              counselorName: studentName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.08),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            ProfileAvatar(
              name: studentName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          studentName,
                          style: AppTextStyle.titleLg.copyWith(
                            color: AppColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: AppTextStyle.labelMd.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg.isNotEmpty ? lastMsg : 'Tap untuk membalas',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNav,
      items: const [
        NavItem(icon: Icons.forum, label: 'Inbox', route: '/admin/inbox'),
      ],
      onTap: (i) => setState(() => _currentNav = i),
    );
  }
}
