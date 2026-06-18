import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../models/counseling_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/counseling_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import 'counseling_chat_page.dart';
import 'profile_page.dart';
import 'student_dashboard_page.dart';

class CounselingRequestPage extends StatefulWidget {
  const CounselingRequestPage({super.key});

  @override
  State<CounselingRequestPage> createState() => _CounselingRequestPageState();
}

class _CounselingRequestPageState extends State<CounselingRequestPage> {
  final _topicController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  int _currentNav = 1;
  String _selectedPriority = 'rendah';

  @override
  void dispose() {
    _topicController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final student = auth.user;
    if (student == null) return;

    try {
      await CounselingService().createCounselingRequest(
        studentId: student.id,
        studentName: student.name,
        studentClass: student.className ?? '',
        topic: _topicController.text.trim(),
        message: _messageController.text.trim(),
        priority: _selectedPriority,
      );
      _topicController.clear();
      _messageController.clear();
      setState(() => _selectedPriority = 'rendah');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan konseling terkirim')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim permintaan')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final studentId = auth.user?.id ?? '';

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
                    'Ajukan Konseling',
                    style: AppTextStyle.headlineLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sampaikan masalahmu kepada Guru BK',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildFormCard(),
                  const SizedBox(height: AppSizes.stackLg),
                  Text(
                    'Riwayat Permintaanku',
                    style: AppTextStyle.titleLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSizes.stackMd),
                  _buildMyRequests(studentId),
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

  Widget _buildFormCard() {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topik',
              style: AppTextStyle.titleLg.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _topicController,
              style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Contoh: Masalah akademik',
                hintStyle: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.outline,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.all(AppSizes.cardPadding),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Isi topik konseling' : null,
            ),
            const SizedBox(height: AppSizes.stackMd),
            Text(
              'Pesan',
              style: AppTextStyle.titleLg.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Jelaskan masalahmu secara singkat...',
                hintStyle: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.outline,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                contentPadding: const EdgeInsets.all(AppSizes.cardPadding),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Isi pesan konseling' : null,
            ),
            const SizedBox(height: AppSizes.stackMd),
            Text(
              'Prioritas',
              style: AppTextStyle.titleLg.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityChip('Rendah', 'rendah', Colors.green),
                const SizedBox(width: 8),
                _buildPriorityChip('Sedang', 'sedang', Colors.orange),
                const SizedBox(width: 8),
                _buildPriorityChip('Tinggi', 'tinggi', Colors.red),
              ],
            ),
            const SizedBox(height: AppSizes.stackLg),
            GestureDetector(
              onTap: _isSubmitting ? null : _submitRequest,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.brandGradientStart,
                      AppColors.brandGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send,
                                color: AppColors.onPrimary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Kirim Permintaan',
                              style: AppTextStyle.titleLg.copyWith(
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRequests(String studentId) {
    return StreamBuilder<List<CounselingRequest>>(
      stream:
          CounselingService().streamStudentRequests(studentId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
              'CounselingRequestPage error: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gagal memuat data',
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
          return const ShimmerList(itemCount: 2);
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.inbox,
            title: 'Belum ada permintaan',
            subtitle: 'Ajukan permintaan konseling di atas',
          );
        }

        return Column(
          children: requests.map((req) => _buildRequestCard(req)).toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(CounselingRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  req.topic,
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
          if (req.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              req.message,
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
              if (req.isAccepted && req.chatId != null)
                GestureDetector(
                  onTap: () => _openChat(req),
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
                      'Chat BK',
                      style: AppTextStyle.labelLg.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String label, String value, Color color) {
    final selected = _selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            border: Border.all(
              color: selected ? color : AppColors.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyle.labelLg.copyWith(
                  color: selected ? color : AppColors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(CounselingRequest req) async {
    final bkSnapshot = await FirebaseService.users
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    if (bkSnapshot.docs.isEmpty || !mounted) return;
    final bkData = bkSnapshot.docs.first.data() as Map<String, dynamic>;
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
    return '${dt.day}/${dt.month}/${dt.year}';
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
            icon: Icons.person, label: 'Profile', route: '/student/profile'),
      ],
      onTap: (i) {
        if (i == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const StudentDashboardPage()),
          );
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
