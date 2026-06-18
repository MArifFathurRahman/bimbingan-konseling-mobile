import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../models/counseling_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/counseling_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shimmer_loading.dart';
import '../student/counseling_chat_page.dart';

class CounselingRequestsPage extends StatefulWidget {
  const CounselingRequestsPage({super.key});

  @override
  State<CounselingRequestsPage> createState() => _CounselingRequestsPageState();
}

class _CounselingRequestsPageState extends State<CounselingRequestsPage> {
  int _currentNav = 1;

  final CounselingService _service = CounselingService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                    'Permintaan Konseling',
                    style: AppTextStyle.headlineLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kelola permintaan konseling dari siswa',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildRequestList(auth),
                ],
              ),
            ),
            _buildBottomNav(),
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
            'SafeSpace',
            style: AppTextStyle.titleLg.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(AuthProvider auth) {
    return StreamBuilder<List<CounselingRequest>>(
      stream: _service.streamAllRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
              'CounselingRequestsPage error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gagal memuat permintaan',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      snapshot.error.toString(),
                      style: AppTextStyle.labelMd.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const ShimmerList(itemCount: 3);
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox,
            title: 'Belum ada permintaan',
            subtitle: 'Permintaan konseling siswa akan muncul di sini',
          );
        }

        return Column(
          children: requests.map((req) => _buildRequestCard(req, auth)).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(CounselingRequest req, AuthProvider auth) {
    final isPending = req.isPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: isPending
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.15))
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(name: req.studentName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            req.studentName,
                            style: AppTextStyle.titleLg.copyWith(
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPriorityBadge(req.priority),
                        const SizedBox(width: 6),
                        _buildStatusBadge(req.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      req.studentClass,
                      style: AppTextStyle.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.topic,
                  style: AppTextStyle.titleLg.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 14,
                  ),
                ),
                if (req.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    req.message,
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                _formatDate(req.createdAt),
                style: AppTextStyle.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (isPending) ...[
                GestureDetector(
                  onTap: () => _rejectRequest(req, auth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'Tolak',
                      style: AppTextStyle.labelLg.copyWith(
                        color: AppColors.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _acceptRequest(req, auth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'Terima',
                      style: AppTextStyle.labelLg.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              if (req.isAccepted && req.chatId != null) ...[
                GestureDetector(
                  onTap: () => _openChat(req),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'Chat',
                      style: AppTextStyle.labelLg.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(CounselingRequest req, AuthProvider auth) async {
    final admin = auth.user;
    if (admin == null) return;

    try {
      await _service.acceptRequest(
        req.id,
        studentId: req.studentId,
        studentName: req.studentName,
        adminId: admin.id,
        adminName: admin.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permintaan dari ${req.studentName} diterima')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menerima permintaan')),
      );
    }
  }

  Future<void> _rejectRequest(CounselingRequest req, AuthProvider auth) async {
    try {
      await _service.rejectRequest(req.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permintaan dari ${req.studentName} ditolak')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menolak permintaan')),
      );
    }
  }

  void _openChat(CounselingRequest req) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CounselingChatPage(
          counselorId: req.studentId,
          counselorName: req.studentName,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyle.labelMd.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'accepted':
        bg = const Color(0xFFbbf7d0);
        fg = const Color(0xFF166534);
        label = 'Diterima';
      case 'rejected':
        bg = const Color(0xFFfecaca);
        fg = const Color(0xFF991b1b);
        label = 'Ditolak';
      default:
        bg = const Color(0xFFfed7aa);
        fg = const Color(0xFF9a3412);
        label = 'Menunggu';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyle.labelLg.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
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

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNav,
      items: const [
        NavItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            route: '/admin/dashboard'),
        NavItem(
            icon: Icons.psychology,
            label: 'Counseling',
            route: '/admin/counseling'),
        NavItem(
            icon: Icons.groups, label: 'Siswa', route: '/admin/siswa'),
        NavItem(
            icon: Icons.assignment,
            label: 'Reports',
            route: '/admin/reports'),
      ],
      onTap: (i) {
        setState(() => _currentNav = i);
      },
    );
  }
}
