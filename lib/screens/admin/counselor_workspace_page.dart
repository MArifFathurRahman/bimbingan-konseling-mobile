import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/utils/student_helper.dart';
import '../../models/counseling_request_model.dart';
import '../../models/notification_model.dart';
import '../../models/student_model.dart';
import '../../services/counseling_service.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/section_title.dart';
import '../../providers/auth_provider.dart';
import '../student/counseling_chat_page.dart';
import 'admin_dashboard_page.dart';
import 'bk_inbox_page.dart';
import 'counseling_requests_page.dart';
import 'input_point_page.dart';
import 'notifications_page.dart';
import 'reports_page.dart';
import 'summon_letter_page.dart';

class CounselorWorkspacePage extends StatefulWidget {
  const CounselorWorkspacePage({super.key});

  @override
  State<CounselorWorkspacePage> createState() => _CounselorWorkspacePageState();
}

class _CounselorWorkspacePageState extends State<CounselorWorkspacePage> {
  int _currentNav = 1;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _notificationService = RealtimeNotificationService();
  StreamSubscription<NotificationItem>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _notificationService.startListening();
    _notificationSub = _notificationService.onNewNotification.listen(_showNewNotificationDialog);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildHeader(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildStatsGrid(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildPriorityCounters(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildInboxButton(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildCounselingRequestsSection(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildPointManagement(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildSummonsCard(),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.marginMobile, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.school, color: AppColors.onPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Text('EduGuard', style: AppTextStyle.headlineMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Spacer(),
          StreamBuilder<int>(
            stream: FirebaseService.notifications
                .where('isRead', isEqualTo: false)
                .where('type', isEqualTo: 'counseling_request')
                .snapshots()
                .map((s) => s.docs.length),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 24),
                      if (count > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Icon(Icons.account_circle, color: AppColors.primary, size: 28),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Counselor Workspace', style: AppTextStyle.headlineMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
        const SizedBox(height: 4),
        Text('Ringkasan aktivitas kedisiplinan hari ini.', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.violations.snapshots(),
      builder: (context, snap) {
        final total = snap.data?.docs.length ?? 0;
        final highRisk = snap.data?.docs.where((doc) {
          final pts = ((doc.data() as Map<String, dynamic>)['points'] as num?)?.toInt() ?? 0;
          return pts >= 25;
        }).length ?? 0;

        return Column(
          children: [
            Row(
              children: [
                Expanded(flex: 2, child: StatCardBento(value: '$total', label: 'Total Laporan', icon: Icons.description, trend: '+$total', trendColor: AppColors.error)),
                const SizedBox(width: AppSizes.gutter),
                Expanded(child: StatCardBento(value: '$highRisk', label: 'High-Risk', icon: Icons.warning, iconColor: AppColors.error, iconBgColor: AppColors.errorContainer)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriorityCounters() {
    return StreamBuilder<Map<String, int>>(
      stream: CounselingService().streamPriorityCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? {'rendah': 0, 'sedang': 0, 'tinggi': 0};
        return Row(
          children: [
            Expanded(
              child: _buildCounterCard(
                'Rendah',
                '${counts['rendah']}',
                Colors.green,
                Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCounterCard(
                'Sedang',
                '${counts['sedang']}',
                Colors.orange,
                Icons.remove,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCounterCard(
                'Tinggi',
                '${counts['tinggi']}',
                Colors.red,
                Icons.arrow_upward,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCounterCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyle.headlineMd.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyle.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BkInboxPage()));
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.forum, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pesan Siswa', style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
                  Text('Lihat dan balas pesan dari siswa',
                      style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildCounselingRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<CounselingRequest>>(
          stream: CounselingService().streamAllRequests(),
          builder: (context, snapshot) {
            final pendingCount = snapshot.data?.where((r) => r.isPending).length ?? 0;
            return SectionTitle(
              title: 'Permintaan Konseling',
              badgeCount: pendingCount,
              actionLabel: 'Lihat Semua',
              actionIcon: Icons.chevron_right,
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CounselingRequestsPage()),
                );
              },
            );
          },
        ),
        const SizedBox(height: AppSizes.stackMd),
        StreamBuilder<List<CounselingRequest>>(
          stream: CounselingService().streamAllRequests(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint(
                  'CounselorWorkspace requests error: ${snapshot.error}');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Gagal memuat permintaan',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const ShimmerList(itemCount: 2);
            }

            final requests = snapshot.data!;
            final pending = requests
                .where((r) => r.isPending)
                .take(3)
                .toList();

            if (requests.isEmpty) {
              return const EmptyState(
                icon: Icons.inbox,
                title: 'Belum ada permintaan',
                subtitle:
                    'Permintaan konseling dari siswa akan muncul di sini',
              );
            }

            return Column(
              children: [
                ...pending.map((req) => _buildRequestCard(req)),
                if (requests.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CounselingRequestsPage()),
                        );
                      },
                      child: Text(
                        '+${requests.length - 3} permintaan lainnya',
                        style: AppTextStyle.labelLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequestCard(CounselingRequest req) {
    final auth = context.read<AuthProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSizes.cardPadding),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(name: req.studentName, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.studentName,
                      style: AppTextStyle.titleLg.copyWith(
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${req.studentClass} \u2022 ${req.topic}',
                      style: AppTextStyle.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildPriorityBadge(req.priority),
              const SizedBox(width: 6),
              _buildStatusBadge(req.status),
            ],
          ),
          if (req.isPending && auth.user != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _rejectRequest(req, auth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
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
                      vertical: 6,
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
            ),
          ],
          if (req.isAccepted && req.chatId != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _openChat(req),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'Buka Chat',
                      style: AppTextStyle.labelLg.copyWith(
                        color: AppColors.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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

  Future<void> _acceptRequest(
      CounselingRequest req, AuthProvider auth) async {
    final admin = auth.user;
    if (admin == null) return;
    try {
      await CounselingService().acceptRequest(
        req.id,
        studentId: req.studentId,
        studentName: req.studentName,
        adminId: admin.id,
        adminName: admin.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permintaan ${req.studentName} diterima')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menerima permintaan')),
      );
    }
  }

  Future<void> _rejectRequest(
      CounselingRequest req, AuthProvider auth) async {
    try {
      await CounselingService().rejectRequest(req.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permintaan ${req.studentName} ditolak')),
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

  Widget _buildPointManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Manajemen Poin',
          actionLabel: 'Quick Add Points',
          actionIcon: Icons.add_circle,
          onActionTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InputPointPage()));
          },
        ),
        const SizedBox(height: AppSizes.stackMd),
        SearchField(controller: _searchController, hint: 'Cari nama siswa atau kelas...'),
        const SizedBox(height: AppSizes.stackMd),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.users
              .limit(100)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              debugPrint('CounselorWorkspace student query error: ${snap.error}');
              return Center(
                child: Text(
                  'Gagal memuat data siswa',
                  style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final allDocs = snap.data!.docs;
            debugPrint('CounselorWorkspace: ${allDocs.length} total users from Firestore');

            List<Student> students = [];
            int ignoredDocs = 0;
            final Set<String> rolesFound = {};
            for (final doc in allDocs) {
              try {
                final raw = doc.data();
                if (raw is! Map<String, dynamic>) continue;
                final role = raw['role'];
                final name = (raw['name'] as String?) ?? '';
                final dept = raw['department'];
                rolesFound.add(role.toString());
                if (!isStudentRole(role) || name.isEmpty) {
                  ignoredDocs++;
                  continue;
                }
                debugPrint('DOC: role="$role" name="$name" dept="$dept"');
                students.add(Student(
                  id: doc.id,
                  name: name,
                  nis: (raw['nis'] as String?) ?? '',
                  className: (raw['className'] as String?) ?? (raw['class'] as String?) ?? '',
                  department: (raw['department'] as String?) ?? '',
                  points: (raw['points'] as num?)?.toInt() ?? 0,
                  status: (raw['status'] as String?) ?? 'Aktif',
                  imageUrl: raw['imageUrl'] as String?,
                ));
              } catch (_) {}
            }

            if (_searchQuery.isNotEmpty) {
              students = students.where((s) =>
                s.name.toLowerCase().contains(_searchQuery) ||
                s.nis.contains(_searchQuery) ||
                s.className.toLowerCase().contains(_searchQuery)
              ).toList();
            }

            debugPrint('CounselorWorkspace: ${allDocs.length} users loaded, '
                '${students.length} students parsed, $ignoredDocs ignored');
            debugPrint('CounselorWorkspace: sample roles found: $rolesFound');

            if (students.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _searchQuery.isNotEmpty ? 'Siswa tidak ditemukan' : 'Belum ada data siswa',
                    style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              );
            }

            return Column(
              children: students.map((student) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStudentPointCard(student),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentPointCard(Student student) {
    Color borderColor;
    Color pointsColor;
    if (student.points >= 50) {
      borderColor = AppColors.error;
      pointsColor = AppColors.error;
    } else if (student.points >= 20) {
      borderColor = AppColors.primary;
      pointsColor = AppColors.primary;
    } else {
      borderColor = AppColors.onSecondaryFixedVariant;
      pointsColor = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Row(
        children: [
          ProfileAvatar(name: student.name, imageUrl: student.imageUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  student.className,
                  style: AppTextStyle.labelLg.copyWith(color: AppColors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('${student.points} Poin',
                  style: AppTextStyle.bodyMd.copyWith(fontWeight: FontWeight.bold, color: pointsColor),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => InputPointPage(student: student))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text('View/Edit',
                  style: AppTextStyle.labelLg.copyWith(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummonsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0, top: 0,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                padding: const EdgeInsets.all(32),
                child: const Icon(Icons.mark_email_unread, size: 120, color: AppColors.onPrimaryContainer),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Surat Panggilan', style: AppTextStyle.headlineMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.onPrimaryContainer)),
              const SizedBox(height: 8),
              Text('Terbitkan surat panggilan resmi (SP) secara digital untuk orang tua siswa.',
                style: AppTextStyle.bodyMd.copyWith(color: AppColors.onPrimaryContainer.withValues(alpha: 0.9))),
              const SizedBox(height: 24),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SummonLetterPage()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Generate PDF Summons', style: AppTextStyle.titleLg.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewNotificationDialog(NotificationItem item) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Permintaan Konseling Baru'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogField('Nama', item.studentName),
            const SizedBox(height: 12),
            _buildDialogField('Prioritas', _priorityLabel(item.priority)),
            const SizedBox(height: 12),
            _buildDialogField('Waktu', _formatDate(item.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CounselingRequestsPage(),
                ),
              );
            },
            child: const Text('Lihat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
        ),
      ],
    );
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'tinggi':
        return '🔴 Tinggi';
      case 'sedang':
        return '🟡 Sedang';
      default:
        return '🟢 Rendah';
    }
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
        NavItem(icon: Icons.dashboard, label: 'Dashboard', route: '/admin/dashboard'),
        NavItem(icon: Icons.psychology, label: 'Counseling', route: '/admin/counseling'),
        NavItem(icon: Icons.assignment, label: 'Reports', route: '/admin/reports'),
      ],
      onTap: (i) {
        setState(() => _currentNav = i);
        if (i == 0) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
        } else if (i == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()));
        }
      },
    );
  }
}
