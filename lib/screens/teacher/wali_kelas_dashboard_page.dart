import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/themes/app_theme.dart';
import '../../core/utils/student_helper.dart';
import '../../models/student_model.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/initial_avatar.dart';
import '../../widgets/point_badge.dart';
import '../../widgets/confirm_dialog.dart';
import '../../routes/app_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../auth/login_page.dart';

class WaliKelasDashboardPage extends StatefulWidget {
  const WaliKelasDashboardPage({super.key});

  @override
  State<WaliKelasDashboardPage> createState() => _WaliKelasDashboardPageState();
}

class _WaliKelasDashboardPageState extends State<WaliKelasDashboardPage> {
  int _currentNav = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Konfirmasi Logout',
      message: 'Apakah Anda yakin ingin logout?',
    );
    if (confirmed && context.mounted) {
      context.read<AuthProvider>().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _navigateToStudentDetail(Student student) {
    Navigator.pushNamed(context, AppRoutes.studentDetail, arguments: student);
  }

  void _onNavTap(int index) {
    if (index == _currentNav) return;
    setState(() => _currentNav = index);
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.monitoringRecords);
    } else if (index == 2) {
      Navigator.pushNamed(context, AppRoutes.teacherProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final className = auth.user?.className ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Stack(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseService.users
                        .where('className', isEqualTo: className).snapshots(),
                    builder: (context, snapshot) {
                      List<Student> students = [];
                      int alertCount = 0;
                      int ignoredDocs = 0;
                      final Set<String> rolesFound = {};

                      if (snapshot.hasData) {
                        for (final doc in snapshot.data!.docs) {
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
                          final student = Student(
                            id: doc.id,
                            name: name,
                            nis: data['nis'] as String? ?? '',
                            className: (data['className'] as String?) ?? (data['class'] as String?) ?? '',
                            department: normalizeDepartment(dept),
                            points: (data['points'] as num?)?.toInt() ?? 0,
                            status: data['status'] as String? ?? 'Aktif',
                            imageUrl: data['imageUrl'] as String?,
                          );
                          students.add(student);
                          if (student.points >= 25) alertCount++;
                        }
                        debugPrint('WaliKelas: ${snapshot.data!.docs.length} users loaded, '
                            '${students.length} students parsed, $ignoredDocs ignored');
                        debugPrint('WaliKelas: sample roles found: $rolesFound');
                      }

                      final filtered = students.where((s) {
                        if (_searchQuery.isEmpty) return true;
                        return s.name.toLowerCase().contains(_searchQuery) ||
                            s.nis.contains(_searchQuery);
                      }).toList();

                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 672),
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 80, 20, 96),
                            children: [
                              _buildPageTitle(className),
                              const SizedBox(height: 24),
                              _buildSearchAndFilter(),
                              const SizedBox(height: 24),
                              _buildStats(students.length, alertCount),
                              const SizedBox(height: 24),
                              _buildStudentListHeader(),
                              const SizedBox(height: 16),
                              ...filtered.map((student) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _StudentMonitoringCard(
                                  student: student,
                                  onTap: () => _navigateToStudentDetail(student),
                                ),
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  _buildFab(),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Image.asset('assets/images/binusa_logo.png', width: 36, height: 36),
          const SizedBox(width: 8),
          Text('SafeSpace', style: AppTextStyle.titleLg.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
            ),
            child: const Icon(Icons.person, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle(String className) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wali Kelas $className', style: AppTextStyle.headlineMd.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('Daily student wellbeing status overview', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: SearchField(
            controller: _searchController,
            hint: 'Search student name...',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: const Icon(Icons.filter_list, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildStats(int totalStudents, int alertCount) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: const Border(left: BorderSide(color: AppColors.green, width: 4)),
              boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL STUDENTS', style: AppTextStyle.labelLg.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('$totalStudents', style: AppTextStyle.headlineLg.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: const Border(left: BorderSide(color: AppColors.error, width: 4)),
              boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ALERTS', style: AppTextStyle.labelLg.copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('$alertCount', style: AppTextStyle.headlineLg.copyWith(color: AppColors.error)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Monitoring Records', style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
        Text('Updated 5m ago', style: AppTextStyle.labelLg.copyWith(color: AppColors.secondary)),
      ],
    );
  }

  Widget _buildFab() {
    return Positioned(
      bottom: 24,
      right: 6,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12)],
        ),
        child: const Icon(Icons.add, color: AppColors.onPrimary, size: 28),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNav,
      items: const [
        NavItem(icon: Icons.dashboard, label: 'Dashboard', route: '/teacher/dashboard'),
        NavItem(icon: Icons.forum, label: 'Counseling', route: '/teacher/counseling'),
        NavItem(icon: Icons.person, label: 'Profile', route: '/teacher/profile'),
      ],
      onTap: _onNavTap,
    );
  }
}

class _StudentMonitoringCard extends StatefulWidget {
  final Student student;
  final VoidCallback onTap;

  const _StudentMonitoringCard({required this.student, required this.onTap});

  @override
  State<_StudentMonitoringCard> createState() => _StudentMonitoringCardState();
}

class _StudentMonitoringCardState extends State<_StudentMonitoringCard> {
  bool _isHovered = false;

  Color get _avatarBg {
    if (widget.student.points >= 25) return AppColors.errorContainer;
    return AppColors.primaryFixed;
  }

  Color get _avatarFg {
    if (widget.student.points >= 25) return AppColors.onErrorContainer;
    return AppColors.onPrimaryFixed;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              InitialAvatar(
                initials: widget.student.initials,
                size: 48,
                backgroundColor: _avatarBg,
                textColor: _avatarFg,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.student.name,
                      style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.student.className,
                      style: AppTextStyle.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PointBadge(points: widget.student.points),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isHovered ? AppColors.primary : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: _isHovered ? AppColors.onPrimary : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
