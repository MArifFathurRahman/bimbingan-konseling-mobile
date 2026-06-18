import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/themes/app_theme.dart';
import '../../core/utils/student_helper.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/pdf_service.dart';
import 'package:printing/printing.dart';
import '../../routes/app_router.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/initial_avatar.dart';
import '../../widgets/point_badge.dart';
import '../../widgets/custom_textfield.dart';

class MonitoringRecordsPage extends StatefulWidget {
  const MonitoringRecordsPage({super.key});

  @override
  State<MonitoringRecordsPage> createState() => _MonitoringRecordsPageState();
}

class _MonitoringRecordsPageState extends State<MonitoringRecordsPage> {
  int _currentNav = 1;
  final _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  String get _searchQuery => _searchController.text.toLowerCase();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToStudentDetail(Student student) {
    Navigator.pushNamed(context, AppRoutes.studentDetail, arguments: student);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final className = auth.user?.className ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SafeSpace', style: AppTextStyle.titleLg.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
            tooltip: 'Export PDF',
            onPressed: () => _exportClassPdf(context, className),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.users
                  .where('className', isEqualTo: className)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Gagal memuat data', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                int ignoredDocs = 0;
                final Set<String> rolesFound = {};
                List<Student> students = [];
                for (final doc in snap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'];
                  final name = data['name'] as String? ?? '';
                  final dept = data['department'];
                  rolesFound.add(role.toString());
                  debugPrint('DOC: role="$role" name="$name" dept="$dept"');
                  if (!isStudentRole(role) || name.isEmpty) {
                    ignoredDocs++;
                    continue;
                  }
                  students.add(Student(
                    id: doc.id,
                    name: name,
                    nis: data['nis'] as String? ?? '',
                    className: (data['className'] as String?) ?? (data['class'] as String?) ?? '',
                    department: normalizeDepartment(dept),
                    points: (data['points'] as num?)?.toInt() ?? 0,
                    status: data['status'] as String? ?? 'Aktif',
                    imageUrl: data['imageUrl'] as String?,
                  ));
                }
                debugPrint('MonitoringRecords: ${snap.data!.docs.length} users loaded, '
                    '${students.length} students parsed, $ignoredDocs ignored');
                debugPrint('MonitoringRecords: sample roles found: $rolesFound');

                final query = _searchQuery;
                if (query.isNotEmpty) {
                  students = students.where((s) =>
                    s.name.toLowerCase().contains(query) || s.nis.contains(query)
                  ).toList();
                }

                if (_selectedFilter == 'High Risk') {
                  students = students.where((s) => s.points >= 25).toList();
                } else if (_selectedFilter == 'Medium') {
                  students = students.where((s) => s.points >= 11 && s.points < 25).toList();
                } else if (_selectedFilter == 'Low') {
                  students = students.where((s) => s.points < 11).toList();
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    SearchField(controller: _searchController, hint: 'Search student name...'),
                    const SizedBox(height: 24),
                    _buildFilterChips(),
                    const SizedBox(height: 24),
                    Text('${students.length} Students', style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
                    const SizedBox(height: 16),
                    if (students.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Text('Tidak ada siswa', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                        ),
                      )
                    else
                      ...students.map((student) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () => _navigateToStudentDetail(student),
                          child: _buildStudentCard(student),
                        ),
                      )),
                  ],
                );
              },
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Monitoring Records', style: AppTextStyle.headlineMd.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Student discipline monitoring overview', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'High Risk', 'Medium', 'Low'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((label) {
          final isActive = _selectedFilter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(9999),
                  border: isActive ? null : Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  label,
                  style: AppTextStyle.labelLg.copyWith(
                    color: isActive ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    Color avatarBg;
    Color avatarFg;
    if (student.points >= 25) {
      avatarBg = AppColors.errorContainer;
      avatarFg = AppColors.onErrorContainer;
    } else if (student.points >= 11) {
      avatarBg = AppColors.yellow.withValues(alpha: 0.15);
      avatarFg = AppColors.yellow;
    } else {
      avatarBg = AppColors.green.withValues(alpha: 0.1);
      avatarFg = AppColors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          InitialAvatar(
            initials: student.initials,
            size: 48,
            backgroundColor: avatarBg,
            textColor: avatarFg,
          ),
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
                const SizedBox(height: 2),
                Text(
                  student.className,
                  style: AppTextStyle.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PointBadge(points: student.points),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Future<void> _exportClassPdf(BuildContext context, String className) async {
    try {
      final snap = await FirebaseService.users
          .where('className', isEqualTo: className)
          .get();
      final students = <Student>[];
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final name = d['name'] as String? ?? '';
        if (!isStudentRole(d['role']) || name.isEmpty) continue;
        students.add(Student(
          id: doc.id,
          name: name,
          nis: d['nis'] as String? ?? '',
          className: (d['className'] as String?) ?? (d['class'] as String?) ?? '',
          department: normalizeDepartment(d['department']),
          points: (d['points'] as num?)?.toInt() ?? 0,
        ));
      }
      students.sort((a, b) => b.points.compareTo(a.points));
      final bytes = await PdfService.generateStudentReport(
        student: students.isNotEmpty ? students.first : Student(id: '', name: 'Kelas $className', nis: '', className: className, department: '', points: 0),
        totalPoints: students.fold<int>(0, (s, e) => s + e.points),
        violationCount: students.length,
        violations: students.map((s) => <String, dynamic>{
          'date': '-',
          'category': s.name,
          'description': 'Kelas ${s.className} \u2022 ${s.department}',
          'points': s.points,
        }).toList(),
      );
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'Monitoring_Kelas_$className',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export PDF: $e')),
      );
    }
  }

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNav,
      items: const [
        NavItem(icon: Icons.dashboard, label: 'Dashboard', route: '/teacher/dashboard'),
        NavItem(icon: Icons.assignment, label: 'Records', route: '/teacher/records'),
        NavItem(icon: Icons.person, label: 'Profile', route: '/teacher/profile'),
      ],
      onTap: (i) => setState(() => _currentNav = i),
    );
  }
}
