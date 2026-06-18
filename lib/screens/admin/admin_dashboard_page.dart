import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/utils/student_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/report_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/point_badge.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_page.dart';
import 'counselor_workspace_page.dart';
import 'input_point_page.dart';
import 'notifications_page.dart';
import 'student_department_page.dart';
import 'summon_letter_page.dart';
import 'reports_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentNav = 0;

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
                  const PageHeader(
                    title: 'Administration Overview',
                    subtitle: 'Real-time monitoring and reporting',
                  ),
                  const SizedBox(height: AppSizes.stackMd),
                  _buildStatsGrid(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildQuickActions(),
                  const SizedBox(height: AppSizes.stackLg),
                  SectionTitle(
                    title: 'Recent Violations',
                    actionLabel: 'View All',
                    actionIcon: Icons.chevron_right,
                    onActionTap: () {},
                  ),
                  const SizedBox(height: AppSizes.stackMd),
                  _buildRecentViolations(),
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
    final auth = context.watch<AuthProvider>();
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.marginMobile),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset('assets/images/binusa_logo.png', width: 36, height: 36),
          const SizedBox(width: 12),
          Text(
            'SafeSpace',
            style: AppTextStyle.titleLg.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
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
                padding: const EdgeInsets.only(right: 4),
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
                      const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant, size: 22),
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
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error, size: 22),
            onPressed: () async {
              final confirmed = await AppDialog.confirm(
                context: context,
                title: 'Konfirmasi Logout',
                message: 'Apakah Anda yakin ingin keluar?',
              );
              if (confirmed) {
                if (!context.mounted) return;
                context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              }
            },
          ),
          const SizedBox(width: 8),
          ProfileAvatar(
            name: auth.user?.name ?? 'Admin',
            imageUrl: auth.user?.imageUrl,
            size: AppSizes.avatarSm,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseService.users.limit(500).snapshots(),
          builder: (context, studentSnap) {
            final allUsers = studentSnap.data?.docs ?? [];
            int studentCount = 0;
            int ignoredDocs = 0;
            final Set<String> allRolesFound = {};
            final Set<String> acceptedRoles = {};
            final Set<String> skippedRoles = {};
            for (final doc in allUsers) {
              final raw = doc.data();
              if (raw is! Map<String, dynamic>) continue;
              final name = (raw['name'] as String?) ?? '';
              final dept = raw['department'];
              final roleRaw = raw['role'];
              final roleStr = roleRaw?.toString() ?? 'NULL';
              allRolesFound.add(roleStr);
              final isStudent = isStudentRole(roleRaw);
              if (isStudent) {
                acceptedRoles.add(roleStr);
              } else {
                skippedRoles.add(roleStr);
              }
              if (isStudent && name.isNotEmpty) {
                studentCount++;
                debugPrint('ACCEPTED DOC: role="$roleStr" name="$name" dept="$dept"');
              } else {
                ignoredDocs++;
                debugPrint(
                    'SKIPPED DOC: name="$name" role="$roleStr" dept="$dept"  reason=${!isStudent ? "not-student-role" : "empty-name"}');
              }
            }
            debugPrint(
                '========== DASHBOARD DEBUG ==========');
            debugPrint('Total users loaded: ${allUsers.length}');
            debugPrint('Students counted: $studentCount');
            debugPrint('Ignored docs: $ignoredDocs');
            debugPrint('ALL UNIQUE ROLES FOUND: $allRolesFound');
            debugPrint('ROLES that PASSED isStudentRole(): $acceptedRoles');
            debugPrint('ROLES that FAILED isStudentRole(): $skippedRoles');
            debugPrint('=====================================');
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.violations.snapshots(),
              builder: (context, violationSnap) {
                final violationCount = violationSnap.data?.docs.length ?? 0;
                final totalPoints = violationSnap.data?.docs.fold<int>(
                  0,
                  (sum, doc) {
                    final pts = ((doc.data() as Map<String, dynamic>)['points'] as num?)?.toInt() ?? 0;
                    return sum + pts;
                  },
                ) ?? 0;
                final highAlert = violationSnap.data?.docs.where((doc) {
                  final pts = ((doc.data() as Map<String, dynamic>)['points'] as num?)?.toInt() ?? 0;
                  return pts >= 25;
                }).length ?? 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            value: '$violationCount',
                            label: 'Total Violations',
                            icon: Icons.description,
                            trend: '+${totalPoints}pts',
                          ),
                        ),
                        const SizedBox(width: AppSizes.gutter),
                        Expanded(
                          child: StatCard(
                            value: '$highAlert',
                            label: 'High Priority Alerts',
                            icon: Icons.priority_high,
                            gradient: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.gutter),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            value: '$studentCount',
                            label: 'Total Students',
                            icon: Icons.groups,
                          ),
                        ),
                        const SizedBox(width: AppSizes.gutter),
                        Expanded(
                          child: StatCard(
                            value: '${violationSnap.data?.docs.length ?? 0}',
                            label: 'Active Reports',
                            icon: Icons.assignment_late,
                            trend: 'new',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: 'Quick Actions'),
        const SizedBox(height: AppSizes.stackMd),
        LayoutBuilder(
          builder: (context, constraints) {
            final ratio = constraints.maxWidth < 400 ? 0.75 : 0.9;
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSizes.gutter,
              mainAxisSpacing: AppSizes.gutter,
              childAspectRatio: ratio,
          children: [
            FeatureCard(
              title: 'Counselor Workspace',
              subtitle: 'Manage sessions & points',
              icon: Icons.psychology,
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CounselorWorkspacePage()));
              },
            ),
            FeatureCard(
              title: 'Input Point',
              subtitle: 'Record violation points',
              icon: Icons.add_circle,
              iconColor: AppColors.secondary,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InputPointPage()));
              },
            ),
            FeatureCard(
              title: 'Student Department',
              subtitle: 'View students by dept',
              icon: Icons.groups,
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentDepartmentPage()));
              },
            ),
            FeatureCard(
              title: 'Summon Generator',
              subtitle: 'Create official summons',
              icon: Icons.mark_email_unread,
              iconColor: AppColors.error,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SummonLetterPage()));
              },
            ),
          ],
        );
          },
        ),
      ],
    );
  }

  Widget _buildRecentViolations() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.violations.orderBy('createdAt', descending: true).limit(4).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load violations'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No violations recorded'));
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.stackSm),
              child: Container(
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
                child: Row(
                  children: [
                    ProfileAvatar(
                      name: (data['studentName'] as String?) ?? 'Unknown',
                      size: AppSizes.avatarMd,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data['studentName'] as String?) ?? 'Unknown',
                            style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (data['violation'] as String?) ?? (data['violationDescription'] as String?) ?? '',
                            style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (data['category'] as String?) ?? '',
                            style: AppTextStyle.labelMd.copyWith(color: AppColors.outline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PointBadge(points: ((data['points'] as num?)?.toInt() ?? 0)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
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
        if (i == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CounselorWorkspacePage()));
        } else if (i == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentDepartmentPage()));
        } else if (i == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()));
        }
      },
    );
  }
}
