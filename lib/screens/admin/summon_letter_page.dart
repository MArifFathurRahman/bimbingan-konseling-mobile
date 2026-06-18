import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/utils/student_helper.dart';
import '../../models/student_model.dart';
import '../../models/violation_model.dart';
import '../../providers/violation_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/section_title.dart';
import '../../widgets/confirm_dialog.dart';
import 'admin_dashboard_page.dart';
import 'reports_page.dart';

class SummonLetterPage extends StatefulWidget {
  const SummonLetterPage({super.key});

  @override
  State<SummonLetterPage> createState() => _SummonLetterPageState();
}

class _SummonLetterPageState extends State<SummonLetterPage> {
  int _currentNav = 1;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedReason = 'Pelanggaran Kedisiplinan';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  Student? _selectedStudent;

  final _reasons = [
    'Pelanggaran Kedisiplinan',
    'Konseling Akademik',
    'Konsultasi Prestasi',
    'Pembinaan Karakter',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                  _buildStudentSelection(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildFormSection(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildPdfPreview(),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildSubmitButton(),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.marginMobile,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school,
              color: AppColors.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'EduGuard',
            style: AppTextStyle.headlineMd.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
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
        Text(
          'Kirim Surat Panggilan',
          style: AppTextStyle.headlineMd.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kelola dan kirim surat panggilan resmi kepada orang tua murid.',
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSelection() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
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
          Text(
            'Pilih Siswa',
            style: AppTextStyle.labelLg.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          SearchField(
            controller: _searchController,
            hint: 'Cari nama atau NISN siswa...',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 72,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.users.limit(100).snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  debugPrint('SummonLetter student error: ${snap.error}');
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final List<Student> students = [];
                int ignoredDocs = 0;
                final Set<String> rolesFound = {};
                for (final doc in snap.data!.docs) {
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
                    students.add(
                      Student(
                        id: doc.id,
                        name: name,
                        nis: (raw['nis'] as String?) ?? '',
                        className:
                            (raw['className'] as String?) ??
                            (raw['class'] as String?) ??
                            '',
                        department: (raw['department'] as String?) ?? '',
                        points: (raw['points'] as num?)?.toInt() ?? 0,
                      ),
                    );
                  } catch (e) {
                    debugPrint('SummonLetter skip doc ${doc.id}: $e');
                  }
                }

                debugPrint('SummonLetter: ${snap.data!.docs.length} users loaded, '
                    '${students.length} students parsed, $ignoredDocs ignored');
                debugPrint('SummonLetter: sample roles found: $rolesFound');

                final filtered = _searchQuery.isNotEmpty
                    ? students.where((s) =>
                        s.name.toLowerCase().contains(_searchQuery) ||
                        s.className.toLowerCase().contains(_searchQuery) ||
                        s.department.toLowerCase().contains(_searchQuery))
                        .toList()
                    : students;

                if (_selectedStudent != null &&
                    filtered.isNotEmpty &&
                    !filtered.any((s) => s.id == _selectedStudent!.id)) {
                  _selectedStudent = null;
                }

                if (_selectedStudent == null &&
                    students.isNotEmpty &&
                    mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted)
                      setState(() => _selectedStudent = filtered.first);
                  });
                }

                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: filtered.map((student) {
                    final isSelected = student.id == _selectedStudent?.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStudent = student),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusXl,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            ProfileAvatar(
                              name: student.name,
                              size: AppSizes.avatarSm,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  student.name,
                                  style: AppTextStyle.bodyMd.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  student.className,
                                  style: AppTextStyle.labelMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    final dateStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    final timeStr = _selectedTime.format(context);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label: 'Alasan Pemanggilan'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedReason,
            items: _reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _selectedReason = v!),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.stackMd),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(label: 'Tanggal'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await AppDialog.pickDate(
                          context,
                          _selectedDate,
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusXl,
                          ),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Text(
                              dateStr,
                              style: AppTextStyle.bodyMd.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_calendar,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(label: 'Waktu'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final time = await AppDialog.pickTime(
                          context,
                          _selectedTime,
                        );
                        if (time != null) setState(() => _selectedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusXl,
                          ),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Text(
                              timeStr,
                              style: AppTextStyle.bodyMd.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.access_time,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.stackMd),
          SectionLabel(label: 'Lokasi Pertemuan'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Text(
              'Ruang Bimbingan Konseling',
              style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  'PDF PREVIEW',
                  style: AppTextStyle.labelMd.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.picture_as_pdf,
                color: AppColors.error,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Surat Panggilan Orang Tua',
                  style: AppTextStyle.titleLg.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedStudent != null
                      ? '${_selectedStudent!.name} - ${_selectedStudent!.className}'
                      : 'Pilih siswa terlebih dahulu',
                  style: AppTextStyle.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: () {
        if (_selectedStudent == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih siswa terlebih dahulu')),
          );
          return;
        }
        final summons = SummonsRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          studentId: _selectedStudent!.id,
          studentName: _selectedStudent!.name,
          reason: _selectedReason,
          date: _selectedDate,
          time: _selectedTime.format(context),
          location: 'Ruang Bimbingan Konseling',
        );
        context.read<ViolationProvider>().addSummons(summons);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Surat panggilan berhasil dikirim ke ${_selectedStudent!.name}',
            ),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandGradientStart, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, color: AppColors.onPrimary),
            const SizedBox(width: 8),
            Text(
              'Kirim & Generate PDF',
              style: AppTextStyle.titleLg.copyWith(color: AppColors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNav,
      items: const [
        NavItem(
          icon: Icons.dashboard,
          label: 'Dashboard',
          route: '/admin/dashboard',
        ),
        NavItem(
          icon: Icons.psychology,
          label: 'Counseling',
          route: '/admin/counseling',
        ),
        NavItem(
          icon: Icons.assignment,
          label: 'Reports',
          route: '/admin/reports',
        ),
      ],
      onTap: (i) {
        setState(() => _currentNav = i);
        if (i == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          );
        } else if (i == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsPage()),
          );
        }
      },
    );
  }
}
