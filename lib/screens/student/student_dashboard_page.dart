import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/report_card.dart';
import '../../widgets/status_badge.dart';
import '../../models/student_model.dart';
import '../../services/firebase_service.dart';
import '../../services/pdf_service.dart';
import 'package:printing/printing.dart';
import '../auth/login_page.dart';
import 'appointment_page.dart';
import 'counseling_request_page.dart';
import 'inbox_page.dart';
import 'point_history_page.dart';
import 'profile_page.dart';
import 'submit_report_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _currentNav = 0;

  Future<void> _logout() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Logout',
      message: 'Apakah Anda yakin ingin logout?',
    );
    if (!confirmed || !mounted) return;
    context.read<AuthProvider>().logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(auth),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseService.userDoc(auth.user!.id).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final name = (data['name'] as String?) ?? '';
                  final className = (data['class'] as String?) ?? '';
                  final department = (data['department'] as String?) ?? '';
                  final points = (data['points'] as int?) ?? 0;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.marginMobile,
                      AppSizes.stackLg,
                      AppSizes.marginMobile,
                      100,
                    ),
                    children: [
                      _buildGreeting(name, className, department),
                      const SizedBox(height: AppSizes.stackLg),
                      _buildSafetyScore(points),
                      const SizedBox(height: AppSizes.stackMd),
                      _buildSummonsAlert(),
                      const SizedBox(height: AppSizes.stackLg),
                      _buildFeatureGrid(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildCounselingRequestCard(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildAppointment(auth.user!.id),
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
          ProfileAvatar(name: auth.user?.name ?? '', size: 36),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _logout,
            child: const Icon(Icons.logout, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String name, String className, String department) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $name',
          style: AppTextStyle.headlineMd.copyWith(
            color: AppColors.onBackground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          'Class $className \u2022 $department',
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyScore(int points) {
    final status = _safetyStatus(points);
    final isAman = status == 'Aman';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -64,
            right: -64,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -48,
            left: -48,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryFixedDim.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                'CURRENT SAFETY SCORE',
                style: AppTextStyle.labelLg.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.8),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$points',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onPrimary,
                      fontFamily: 'Inter',
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'pts',
                    style: TextStyle(
                      fontSize: 22,
                      color: AppColors.onPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              isAman ? StatusBadge.safe() : StatusBadge.peringatan(),
              const SizedBox(height: 16),
              Text(
                isAman
                    ? 'Your score is good. Keep it up!'
                    : 'Your score needs attention (${status}). Please check your violations.',
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColors.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
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

  Widget _buildSummonsAlert() {
    return WarningAlert(
      title: 'Official Summons',
      message: "New 'Surat Panggilan' received",
      buttonLabel: 'View PDF',
      onButtonTap: () => _viewSummonPdf(context),
    );
  }

  Future<void> _viewSummonPdf(BuildContext context) async {
    try {
      final auth = context.read<AuthProvider>();
      final user = auth.user;
      if (user == null) return;
      final studentId = user.id;

      final sumSnap = await FirebaseService.summons
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (sumSnap.docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada surat panggilan')),
        );
        return;
      }

      final sumData = sumSnap.docs.first.data() as Map<String, dynamic>;
      final reason = (sumData['reason'] as String?) ?? 'Pelanggaran Kedisiplinan';
      final rawDate = sumData['date'];
      final date = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();
      final location = (sumData['location'] as String?) ?? 'Ruang BK';

      final violSnap = await FirebaseService.violations
          .where('studentId', isEqualTo: studentId)
          .get();

      final violations = violSnap.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final dDate = d['createdAt'] != null
            ? (d['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        const ms = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        return <String, dynamic>{
          'date': '${dDate.day} ${ms[dDate.month - 1]} ${dDate.year}',
          'category': (d['category'] as String?) ?? '-',
          'description': (d['violation'] as String?) ?? '-',
          'points': (d['points'] as num?)?.toInt() ?? 0,
        };
      }).toList();

      final userDoc = await FirebaseService.userDoc(studentId).get();
      final ud = userDoc.data() as Map<String, dynamic>? ?? {};
      final student = Student(
        id: studentId,
        name: user.name,
        nis: (ud['nis'] as String?) ?? '',
        className: (ud['className'] as String?) ?? (ud['class'] as String?) ?? '',
        department: (ud['department'] as String?) ?? '',
        points: (ud['points'] as num?)?.toInt() ?? 0,
      );

      final bytes = await PdfService.generateSummonLetter(
        student: student,
        reason: reason,
        date: date,
        location: location,
        violations: violations,
      );

      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'Surat_Panggilan_${user.name}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat PDF: $e')),
      );
    }
  }

  Widget _buildFeatureGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = constraints.maxWidth < 400 ? 1.0 : 1.1;
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSizes.gutter,
          mainAxisSpacing: AppSizes.gutter,
          childAspectRatio: ratio,
          children: [
            FeatureCard(
              title: 'History Log',
              subtitle: 'Points history & records',
              icon: Icons.history,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PointHistoryPage()),
                );
              },
            ),
            FeatureCard(
              title: 'Inbox',
              subtitle: 'Chat with Guru BK',
              icon: Icons.forum,
              iconColor: AppColors.secondary,
              showNotificationDot: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InboxPage()),
                );
              },
            ),
            FeatureCard(
              title: 'New Report',
              subtitle: 'Submit safety concern',
              icon: Icons.campaign,
              iconColor: AppColors.error,
              bgColor: AppColors.errorContainer,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubmitReportPage()),
                );
              },
            ),
            FeatureCard(
              title: 'Appointment',
              subtitle: 'Schedule counseling',
              icon: Icons.calendar_month,
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCounselingRequestCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CounselingRequestPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.onPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: const Icon(
                Icons.psychology,
                color: AppColors.onPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajukan Konseling',
                    style: AppTextStyle.titleLg.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sampaikan masalahmu ke Guru BK',
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.onPrimary.withValues(alpha: 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointment(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.appointments.snapshots(),
      builder: (context, snapshot) {
        final appointments = snapshot.data?.docs
                .map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  d['id'] = doc.id;
                  return d;
                })
                .where((d) =>
                    d['studentId'] == studentId &&
                    d['status'] == 'upcoming')
                .toList() ??
            [];

        if (appointments.isNotEmpty) {
          final data = appointments.first;
          final title = (data['title'] as String?) ?? 'Upcoming Appointment';
          final description = (data['description'] as String?) ?? '';
          final counselorName = (data['counselorName'] as String?) ?? '';
          final time = (data['time'] as String?) ?? '';
          final room = (data['room'] as String?) ?? '';
          final dateStr = (data['date'] as String?) ?? '';

          String dayLabel = '';
          if (dateStr.isNotEmpty) {
            final parsedDate = DateTime.tryParse(dateStr);
            if (parsedDate != null) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final tomorrow = DateTime(now.year, now.month, now.day + 1);
              final appDate =
                  DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
              if (appDate == today) {
                dayLabel = 'Today';
              } else if (appDate == tomorrow) {
                dayLabel = 'Tomorrow';
              } else {
                dayLabel = '${parsedDate.day}/${parsedDate.month}';
              }
            }
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(AppSizes.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.05)),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyle.titleLg.copyWith(
                                color: AppColors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: AppTextStyle.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (dayLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            dayLabel,
                            style: AppTextStyle.labelLg.copyWith(
                              color: AppColors.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radius2xl),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusXl),
                          ),
                          child: const Icon(Icons.person,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                counselorName,
                                style: AppTextStyle.labelLg.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$time \u2022 $room',
                                style: AppTextStyle.labelMd.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.event, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSizes.radius2xl),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.event,
                    color: AppColors.primary.withValues(alpha: 0.5)),
                const SizedBox(width: 12),
                Text(
                  'No upcoming appointments',
                  style: AppTextStyle.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNav,
      items: const [
        NavItem(icon: Icons.dashboard, label: 'Dashboard', route: '/student/dashboard'),
        NavItem(icon: Icons.forum, label: 'Counseling', route: '/student/counseling'),
        NavItem(icon: Icons.person, label: 'Profile', route: '/student/profile'),
      ],
      onTap: (i) {
        if (i == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InboxPage()),
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
