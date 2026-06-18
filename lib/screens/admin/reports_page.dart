import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/themes/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/point_badge.dart';
import 'admin_dashboard_page.dart';
import 'counselor_workspace_page.dart';
import 'student_department_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _currentNav = 3;
  String _selectedFilter = 'Semua';

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
                padding: const EdgeInsets.fromLTRB(AppSizes.marginMobile, AppSizes.stackLg, AppSizes.marginMobile, 100),
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSizes.stackMd),
                  _buildStatsOverview(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildFilterTabs(),
                  const SizedBox(height: AppSizes.stackMd),
                  _buildReportList(),
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
        boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text('SafeSpace', style: AppTextStyle.titleLg.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Spacer(),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.outlineVariant)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reports', style: AppTextStyle.headlineMd.copyWith(color: AppColors.onSurface)),
        const SizedBox(height: 4),
        Text('Real-time monitoring reports', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.violations.snapshots(),
      builder: (context, snap) {
        final total = snap.data?.docs.length ?? 0;
        return Row(
          children: [
            Expanded(
              child: _buildStatItem(Icons.gavel, 'Total Laporan', '$total', AppColors.error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.counselingRequests.snapshots(),
                builder: (context, reqSnap) {
                  final pending = reqSnap.data?.docs.where((d) {
                    return (d.data() as Map<String, dynamic>)['status'] == 'pending';
                  }).length ?? 0;
                  return _buildStatItem(Icons.psychology, 'Konseling', '$pending', AppColors.secondary);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.summons.snapshots(),
                builder: (context, sumSnap) {
                  final count = sumSnap.data?.docs.length ?? 0;
                  return _buildStatItem(Icons.mark_email_unread, 'Panggilan', '$count', AppColors.primary);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyle.headlineMd.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(label, style: AppTextStyle.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Semua', 'Pelanggaran', 'Konseling', 'Panggilan', 'Laporan'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final active = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(9999),
                  border: active ? null : Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(f, style: AppTextStyle.labelLg.copyWith(color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReportList() {
    if (_selectedFilter == 'Semua') {
      return Column(
        children: [
          _buildStudentReportsSection(),
          const SizedBox(height: AppSizes.stackLg),
          _buildViolationsSection(),
          const SizedBox(height: AppSizes.stackLg),
          _buildCounselingRequestsSection(),
          const SizedBox(height: AppSizes.stackLg),
          _buildSummonsSection(),
        ],
      );
    }
    if (_selectedFilter == 'Pelanggaran') {
      return _buildViolationsSection();
    }
    if (_selectedFilter == 'Konseling') {
      return _buildCounselingRequestsSection();
    }
    if (_selectedFilter == 'Panggilan') {
      return _buildSummonsSection();
    }
    if (_selectedFilter == 'Laporan') {
      return _buildStudentReportsSection();
    }
    return const SizedBox.shrink();
  }

  Widget _buildStudentReportsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.reports
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState('Belum ada laporan siswa');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan Siswa', style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return _buildReportCard(
                name: (d['userName'] as String?) ?? '',
                type: 'Laporan',
                desc: (d['description'] as String?) ?? '',
                points: 0,
                date: d['createdAt'] != null ? _formatDate((d['createdAt'] as Timestamp).toDate()) : '',
                icon: Icons.description,
                iconColor: AppColors.primary,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildViolationsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.violations
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState('Belum ada laporan pelanggaran');
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _buildReportCard(
              name: (d['studentName'] as String?) ?? '',
              type: 'Pelanggaran',
              desc: (d['violation'] as String?) ?? (d['violationDescription'] as String?) ?? '',
              points: (d['points'] as num?)?.toInt() ?? 0,
              date: d['createdAt'] != null ? _formatDate((d['createdAt'] as Timestamp).toDate()) : '',
              icon: Icons.gavel,
              iconColor: AppColors.error,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCounselingRequestsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.counselingRequests
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState('Belum ada permintaan konseling');
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _buildReportCard(
              name: (d['studentName'] as String?) ?? '',
              type: (d['status'] as String?) ?? 'Konseling',
              desc: 'Direkomendasikan oleh ${d['requestedByName'] ?? ''}',
              points: 0,
              date: d['createdAt'] != null ? _formatDate((d['createdAt'] as Timestamp).toDate()) : '',
              icon: Icons.psychology,
              iconColor: AppColors.secondary,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummonsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.summons
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState('Belum ada surat panggilan');
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _buildReportCard(
              name: (d['studentName'] as String?) ?? '',
              type: 'Panggilan',
              desc: (d['reason'] as String?) ?? '',
              points: 0,
              date: d['date'] != null ? _formatDate((d['date'] as Timestamp).toDate()) : '',
              icon: Icons.mark_email_unread,
              iconColor: AppColors.primary,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReportCard({
    required String name,
    required String type,
    required String desc,
    required int points,
    required String date,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(date, style: AppTextStyle.labelMd.copyWith(color: AppColors.outline)),
                ],
              ],
            ),
          ),
          if (points > 0) PointBadge(points: points),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Text(message, style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNav,
      items: const [
        NavItem(icon: Icons.dashboard, label: 'Dashboard', route: '/admin/dashboard'),
        NavItem(icon: Icons.psychology, label: 'Counseling', route: '/admin/counseling'),
        NavItem(icon: Icons.groups, label: 'Siswa', route: '/admin/siswa'),
        NavItem(icon: Icons.assignment, label: 'Reports', route: '/admin/reports'),
      ],
      onTap: (i) {
        setState(() => _currentNav = i);
        if (i == 0) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
        } else if (i == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CounselorWorkspacePage()));
        } else if (i == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentDepartmentPage()));
        }
      },
    );
  }
}
