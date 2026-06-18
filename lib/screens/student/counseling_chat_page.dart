import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/utils/safe_display.dart';
import '../../models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/counseling_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/profile_avatar.dart';

class CounselingChatPage extends StatefulWidget {
  final String counselorId;
  final String counselorName;
  final String? counselorImageUrl;
  final bool counselorIsOnline;

  const CounselingChatPage({
    super.key,
    required this.counselorId,
    required this.counselorName,
    this.counselorImageUrl,
    this.counselorIsOnline = true,
  });

  @override
  State<CounselingChatPage> createState() => _CounselingChatPageState();
}

class _CounselingChatPageState extends State<CounselingChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _autoScroll = true;

  String get _chatId {
    final ids = [_currentUserId, widget.counselorId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  String get _currentUserId =>
      context.read<AuthProvider>().user?.id ?? '';

  String get _senderRole {
    final auth = context.read<AuthProvider>();
    if (auth.isStudent) return 'student';
    if (auth.isAdmin) return 'admin';
    return 'waliKelas';
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    CounselingService().sendMessage(
      chatId: _chatId,
      senderId: user.id,
      receiverId: widget.counselorId,
      senderName: user.name,
      receiverName: widget.counselorName,
      senderRole: _senderRole,
      text: text,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  ChatMessage? _parseMessage(QueryDocumentSnapshot doc) {
    try {
      final raw = doc.data();
      final data =
          (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
      return ChatMessage(
        id: doc.id,
        senderId: (data['senderId'] as String?) ?? '',
        receiverId: (data['receiverId'] as String?) ?? '',
        senderName: (data['senderName'] as String?) ?? '',
        text: (data['text'] as String?) ?? '',
        createdAt: data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _currentUserId;
    final displayName = safeDisplayName(widget.counselorName, 'Siswa');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(displayName),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.messages(_chatId)
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint(
                        'CounselingChatPage error: ${snapshot.error}');
                    return Center(
                      child: Text('Gagal memuat pesan',
                          style: AppTextStyle.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }

                  final messages = snapshot.data!.docs
                      .map((doc) => _parseMessage(doc))
                      .whereType<ChatMessage>()
                      .toList();

                  if (messages.isNotEmpty && _autoScroll) {
                    WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _scrollToBottom());
                    _autoScroll = false;
                  }

                  return GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Container(
                      color: AppColors.background,
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSizes.marginMobile,
                          16,
                          AppSizes.marginMobile,
                          16,
                        ),
                        children: [
                          if (messages.isEmpty)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'Mulai percakapan dengan BK',
                                  style: AppTextStyle.bodyMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...messages.map(
                              (msg) => ChatBubble(
                                message: msg,
                                isMine: msg.senderId == currentUserId,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String displayName) {
    return Container(
      height: 64,
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.marginMobile),
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
            child: Container(
              padding: const EdgeInsets.all(8),
              child:
                  const Icon(Icons.arrow_back, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          ProfileAvatar(
            name: displayName,
            imageUrl: widget.counselorImageUrl,
            showOnlineDot: widget.counselorIsOnline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyle.titleLg.copyWith(
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Online',
                  style: AppTextStyle.labelLg.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: AppTextStyle.bodyMd.copyWith(
                    color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: AppTextStyle.bodyMd.copyWith(
                    color: AppColors.outlineVariant,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: AppColors.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
