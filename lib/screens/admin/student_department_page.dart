import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/utils/student_helper.dart';
import '../../models/student_model.dart';
import '../../services/firebase_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/status_badge.dart';
import 'admin_dashboard_page.dart';
import 'input_point_page.dart';
import 'counselor_workspace_page.dart';
import 'reports_page.dart';

class StudentDepartmentPage extends StatefulWidget {
  const StudentDepartmentPage({super.key});

  @override
  State<StudentDepartmentPage> createState() => _StudentDepartmentPageState();
}

bool _deptMatches(String dept, String selectedDept) =>
    normalizeDepartment(dept).toLowerCase() == normalizeDepartment(selectedDept).toLowerCase();

class _StudentDepartmentPageState extends State<StudentDepartmentPage> {
  int _currentNav = 2;
  String _selectedDept = 'TJKT';
  String _selectedClass = 'Semua';
  final _searchController = TextEditingController();

  final _departments = ['TJKT', 'DKV', 'MPLB', 'AKL'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.users.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Gagal memuat data', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)));
                  }

                  int ignoredDocs = 0;
                  final Set<String> rolesFound = {};
                  var allStudents = <Student>[];
                  for (final doc in snap.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final role = d['role'];
                    final name = d['name'] as String? ?? '';
                    final dept = d['department'];
                    rolesFound.add(role.toString());
                    debugPrint('DOC: role="$role" name="$name" dept="$dept"');
                    if (!isStudentRole(role) || name.isEmpty) {
                      ignoredDocs++;
                      continue;
                    }
                    allStudents.add(Student(
                      id: doc.id,
                      name: name,
                      nis: d['nis'] as String? ?? '',
                      className: (d['className'] as String?) ?? (d['class'] as String?) ?? '',
                      department: normalizeDepartment(dept),
                      points: (d['points'] as num?)?.toInt() ?? 0,
                      status: d['status'] as String? ?? 'Aktif',
                      imageUrl: d['imageUrl'] as String?,
                    ));
                  }
                  debugPrint('DeptPage: ${snap.data!.docs.length} users loaded, '
                      '${allStudents.length} students parsed, $ignoredDocs ignored');
                  debugPrint('DeptPage: sample roles found: $rolesFound');

                  allStudents = allStudents.where((s) => _deptMatches(s.department, _selectedDept)).toList();

                  final uniqueClasses = allStudents.map((s) => s.className).where((c) => c.isNotEmpty).toSet().toList()..sort();

                  if (searchQuery.isNotEmpty) {
                    allStudents = allStudents.where((s) =>
                      s.name.toLowerCase().contains(searchQuery) ||
                      s.className.toLowerCase().contains(searchQuery) ||
                      s.nis.contains(searchQuery)
                    ).toList();
                  }

                  final Map<String, List<Student>> grouped = {};
                  for (final s in allStudents) {
                    if (_selectedClass != 'Semua' && s.className != _selectedClass) continue;
                    grouped.putIfAbsent(s.className, () => []).add(s);
                  }

                  final classNames = grouped.keys.toList()..sort();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(AppSizes.marginMobile, AppSizes.stackLg, AppSizes.marginMobile, 100),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppSizes.stackMd),
                      _buildDeptTabs(),
                      const SizedBox(height: 12),
                      _buildClassFilterChips(uniqueClasses),
                      const SizedBox(height: 12),
                      SearchField(controller: _searchController, hint: 'Cari nama, kelas, atau NIS...', onChanged: (_) => setState(() {})),
                      const SizedBox(height: AppSizes.stackLg),
                      if (allStudents.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Text('Tidak ada siswa yang cocok', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                          ),
                        )
                      else
                        ...classNames.map((cls) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.stackLg),
                          child: _buildClassSection(cls, '${grouped[cls]!.length} Siswa', grouped[cls]!),
                        )),
                    ],
                  );
                },
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
      decoration: BoxDecoration(color: AppColors.surface, boxShadow: [
        BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20),
      ]),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.school, color: AppColors.onPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Text('EduGuard', style: AppTextStyle.headlineMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Spacer(),
          const Icon(Icons.account_circle, color: AppColors.primary, size: 28),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daftar Siswa per Jurusan', style: AppTextStyle.headlineLg.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Kelola poin dan kedisiplinan siswa berdasarkan departemen.', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildDeptTabs() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _departments.map((dept) {
          final isActive = dept == _selectedDept;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedDept = dept;
                _selectedClass = 'Semua';
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: isActive ? null : Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  dept, style: AppTextStyle.labelLg.copyWith(
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

  Widget _buildClassFilterChips(List<String> uniqueClasses) {
    final allLabels = ['Semua', ...uniqueClasses];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: allLabels.map((cls) {
          final isActive = cls == _selectedClass;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedClass = cls),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.secondaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: isActive ? null : Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  cls,
                  style: AppTextStyle.labelMd.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClassSection(String title, String count, List<Student> students) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 24, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
            const Spacer(),
            ClassBadge(label: count),
          ],
        ),
        const SizedBox(height: AppSizes.stackMd),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final ratio = width < 400 ? 0.85 : 1.1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: ratio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: students.length,
              itemBuilder: (context, index) => _buildStudentPointCard(students[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentPointCard(Student student) {
    final isWarning = student.status == 'Peringatan';
    final progress = student.points / 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(name: student.name, imageUrl: student.imageUrl, size: AppSizes.avatarMd),
              const SizedBox(width: 8),
              Flexible(
                child: StatusBadge(
                  label: student.status,
                  backgroundColor: isWarning ? AppColors.errorContainer : AppColors.green.withValues(alpha: 0.1),
                  textColor: isWarning ? AppColors.onErrorContainer : AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            student.name,
            style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text('NIS: ${student.nis}', style: AppTextStyle.labelMd.copyWith(color: AppColors.outline), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Poin', style: AppTextStyle.labelMd.copyWith(color: AppColors.onSurfaceVariant, fontSize: 9)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${student.points}', style: AppTextStyle.headlineMd.copyWith(color: isWarning ? AppColors.error : AppColors.primary, fontSize: 18)),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 32, height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.surfaceContainerHigh,
                              valueColor: AlwaysStoppedAnimation<Color>(isWarning ? AppColors.error : AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InputPointPage(student: student))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.add_circle, color: AppColors.onPrimary, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        } else if (i == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()));
        }
      },
    );
  }
}
