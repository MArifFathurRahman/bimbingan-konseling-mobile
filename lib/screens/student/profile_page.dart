import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../models/counseling_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../services/counseling_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/profile_avatar.dart';
import '../admin/admin_dashboard_page.dart';
import '../teacher/wali_kelas_dashboard_page.dart';
import 'student_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentNav = 2;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isStudent = auth.isStudent;
    final isWaliKelas = auth.isWaliKelas;
    final isAdmin = auth.isAdmin;
    final uid = user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(auth),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseService.userDoc(uid).snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.hasData && snapshot.data!.exists
                      ? snapshot.data!.data() as Map<String, dynamic>
                      : <String, dynamic>{};

                  final name = (data['name'] as String?) ?? user?.name ?? '';
                  final email = (data['email'] as String?) ?? user?.email ?? '';
                  final nip = (data['nip'] as String?) ?? '';
                  final role = (data['role'] as String?) ?? '';
                  final className =
                      (data['className'] as String?) ?? (data['class'] as String?) ?? '';
                  final nis = (data['nis'] as String?) ?? '';
                  final points = (data['points'] as num?)?.toInt() ?? 0;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.marginMobile,
                      AppSizes.stackLg,
                      AppSizes.marginMobile,
                      100,
                    ),
                    children: [
                      _buildProfileHeader(name, className, nis, isStudent, isWaliKelas, isAdmin, role),
                      const SizedBox(height: AppSizes.stackLg),
                      _buildInfoSection(name, email, nip, isStudent),
                      if (isStudent) ...[
                        const SizedBox(height: AppSizes.stackLg),
                        _buildSafetyScore(points),
                        const SizedBox(height: AppSizes.stackLg),
                        _buildCounselingHistory(),
                      ],
                    ],
                  );
                },
              ),
            ),
            _buildBottomNav(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AuthProvider auth) {
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
          Expanded(
            child: Text(
              'Profil Saya',
              style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<AuthProvider>().logout();
              AppRoutes.replaceWith(context, AppRoutes.login);
            },
            child: const Icon(Icons.logout, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String name,
    String className,
    String nis,
    bool isStudent,
    bool isWaliKelas,
    bool isAdmin,
    String role,
  ) {
    return Column(
      children: [
        ProfileAvatar(name: name, size: 80),
        const SizedBox(height: 16),
        Text(
          name,
          style: AppTextStyle.headlineMd.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 4),
        if (isStudent) ...[
          Text(
            className.isNotEmpty ? 'Class $className' : '',
            style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          if (nis.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(
                'NIS: $nis',
                style: AppTextStyle.labelLg.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ] else if (isWaliKelas) ...[
          Text(
            className.isNotEmpty ? 'Wali Kelas $className' : 'Wali Kelas',
            style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ] else if (isAdmin) ...[
          Text(
            'Admin BK',
            style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection(String name, String email, String nip, bool isStudent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Akun',
          style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.person_outline, 'Nama', name),
        const Divider(height: 24),
        _buildInfoRow(Icons.email_outlined, 'Email', email),
        if (nip.isNotEmpty) ...[
          const Divider(height: 24),
          _buildInfoRow(
            isStudent ? Icons.badge_outlined : Icons.badge_outlined,
            isStudent ? 'NIS' : 'NIP',
            nip,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.outline, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyle.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            Text(
              value,
              style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSafetyScore(int points) {
    final status = _safetyStatus(points);
    final isAman = status == 'Aman';

    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.25),
            blurRadius: 40,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safety Score',
                  style: AppTextStyle.labelLg.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$points',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'pts',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.onPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAman ? AppColors.green : AppColors.error,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAman ? Icons.check_circle : Icons.warning,
                  size: 16,
                  color: AppColors.onPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _safetyStatus(int points) {
    if (points <= 20) return 'Aman';
    if (points <= 50) return 'Perhatian';
    if (points <= 80) return 'Risiko';
    return 'Bahaya';
  }

  Widget _buildCounselingHistory() {
    final auth = context.watch<AuthProvider>();
    final studentId = auth.user?.id ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Konseling',
          style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<CounselingRequest>>(
          stream: CounselingService().streamStudentRequests(studentId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    '${snapshot.error}',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final requests = snapshot.data!;
            if (requests.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Belum ada riwayat konseling',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: requests.map((req) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor.withValues(alpha: 0.08),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.chat,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.topic,
                              style: AppTextStyle.labelLg.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                _buildReqPriorityBadge(req.priority),
                                const SizedBox(width: 6),
                                _buildReqStatusBadge(req.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(Icons.access_time, size: 14, color: AppColors.outline),
                          const SizedBox(height: 2),
                          Text(
                            _formatReqDate(req.createdAt),
                            style: AppTextStyle.labelMd.copyWith(
                              color: AppColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReqPriorityBadge(String priority) {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Widget _buildReqStatusBadge(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyle.labelMd.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  String _formatReqDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildBottomNav(AuthProvider auth) {
    final isStudent = auth.isStudent;
    final isWaliKelas = auth.isWaliKelas;

    return BottomNavBar(
      currentIndex: _currentNav,
      items: [
        NavItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          route: isStudent
              ? '/student/dashboard'
              : isWaliKelas
                  ? '/teacher/dashboard'
                  : '/admin/dashboard',
        ),
        NavItem(
          icon: Icons.person,
          label: 'Profile',
          route: isStudent
              ? '/student/profile'
              : isWaliKelas
                  ? '/teacher/profile'
                  : '/admin/profile',
        ),
      ],
      onTap: (i) {
        if (i == 0) {
          Widget destination;
          if (isStudent) {
            destination = const StudentDashboardPage();
          } else if (isWaliKelas) {
            destination = const WaliKelasDashboardPage();
          } else {
            destination = const AdminDashboardPage();
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        } else {
          setState(() => _currentNav = i);
        }
      },
    );
  }
}
