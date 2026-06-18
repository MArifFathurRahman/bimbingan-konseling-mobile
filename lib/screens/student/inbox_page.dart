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
import '../../widgets/custom_textfield.dart';
import '../../widgets/profile_avatar.dart';
import 'counseling_chat_page.dart';
import 'profile_page.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  int _currentNav = 1;
  final _searchController = TextEditingController();

  Map<String, dynamic>? _safeData(QueryDocumentSnapshot doc) {
    final raw = doc.data();
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  Future<void> _startChatWithBK() async {
    final auth = context.read<AuthProvider>();
    final student = auth.user;
    if (student == null) return;

    final bkSnapshot = await FirebaseService.users
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (bkSnapshot.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada BK yang tersedia')),
      );
      return;
    }

    final bkDataRaw = bkSnapshot.docs.first.data();
    final bkData = (bkDataRaw is Map<String, dynamic>) ? bkDataRaw : <String, dynamic>{};
    final bkId = bkSnapshot.docs.first.id;
    final bkName = (bkData['name'] as String?) ?? 'BK';

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CounselingChatPage(
          counselorId: bkId,
          counselorName: bkName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.id ?? '';

    if (auth.isWaliKelas) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Text(
              'Akses tidak tersedia untuk Wali Kelas',
              style: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

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
                    'Inbox',
                    style: AppTextStyle.headlineLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSizes.stackMd),
                  SearchField(
                    controller: _searchController,
                    hint: 'Search conversations...',
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
          debugPrint('InboxPage error: ${snapshot.error}');
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
              child: Column(
                children: [
                  Text(
                    'Belum ada percakapan',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _startChatWithBK,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Text(
                        'Hubungi BK',
                        style: AppTextStyle.labelLg.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
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

            final otherId = participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => participants.last);
            if (otherId.isEmpty) return const SizedBox.shrink();

            final otherInfo = (participantInfo?[otherId] is Map)
                ? (participantInfo![otherId] as Map<String, dynamic>)
                : null;
            final rawName = (otherInfo?['name'] as String?) ?? '';
            final otherName = safeDisplayName(rawName, 'Guru BK');

            final lastMsgText =
                (lastMessage?['text'] as String?) ?? '';

            return _buildConversationCard(
              otherId: otherId,
              otherName: otherName,
              lastMsg: lastMsgText,
              lastMsgSender:
                  (lastMessage?['senderName'] as String?) ?? '',
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
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
    required String otherId,
    required String otherName,
    required String lastMsg,
    required String lastMsgSender,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CounselingChatPage(
              counselorId: otherId,
              counselorName: otherName,
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
              name: otherName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: AppTextStyle.titleLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg.isNotEmpty
                        ? lastMsg
                        : 'Tap to start chatting',
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
        NavItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            route: '/student/dashboard'),
        NavItem(
            icon: Icons.forum,
            label: 'Counseling',
            route: '/student/counseling'),
        NavItem(
            icon: Icons.person,
            label: 'Profile',
            route: '/student/profile'),
      ],
      onTap: (i) {
        if (i == 0) {
          Navigator.pop(context);
        } else if (i == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        } else {
          setState(() => _currentNav = i);
        }
      },
    );
  }
}
