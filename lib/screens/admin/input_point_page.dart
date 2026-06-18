import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/utils/student_helper.dart';
import '../../models/student_model.dart';
import '../../models/violation_model.dart';
import '../../services/violation_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/point_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/section_title.dart';
import '../../widgets/confirm_dialog.dart';

class InputPointPage extends StatefulWidget {
  final Student? student;

  const InputPointPage({super.key, this.student});

  @override
  State<InputPointPage> createState() => _InputPointPageState();
}

class _InputPointPageState extends State<InputPointPage> {
  int _currentNav = 1;
  final _detailController = TextEditingController();
  final _searchController = TextEditingController();
  ViolationCategory? _selectedCategory;
  ViolationItem? _selectedItem;
  DateTime _selectedDate = DateTime.now();
  String _dateLabel = '';
  Student? _selectedStudent;
  String _searchQuery = '';

  final _categories = ViolationService.categories;

  @override
  void initState() {
    super.initState();
    _updateDateLabel();
    _selectedStudent = widget.student;
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories[0];
    }
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _detailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateDateLabel() {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    setState(() {
      _dateLabel = '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Input Point'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
              child: _selectedStudent == null
                  ? _buildStudentSelector()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.marginMobile, AppSizes.stackLg, AppSizes.marginMobile, 100),
                      children: [
                        _buildBackHeader(),
                        const SizedBox(height: AppSizes.stackLg),
                        _buildStudentProfile(_selectedStudent!),
                        const SizedBox(height: AppSizes.stackLg),
                        _buildCategorySection(),
                        if (_selectedCategory != null) ...[
                          const SizedBox(height: AppSizes.stackLg),
                          _buildViolationItems(),
                        ],
                        const SizedBox(height: AppSizes.stackLg),
                        _buildDetailSection(),
                        const SizedBox(height: AppSizes.stackLg),
                        _buildDateSection(),
                        const SizedBox(height: AppSizes.stackLg),
                        _buildSubmitButton(),
                        const SizedBox(height: 16),
                        _buildFooterNote(),
                      ],
                    ),
            ),
            _buildBottomNav(),
          ],
        ),
    );
  }

  Widget _buildBackHeader() {
    final isStandaloneForm = _selectedStudent != null && widget.student == null;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (isStandaloneForm) {
              setState(() => _selectedStudent = null);
            } else {
              Navigator.pop(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isStandaloneForm ? 'Ganti Siswa' : 'Input Poin Siswa',
          style: AppTextStyle.headlineMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.onBackground),
        ),
      ],
    );
  }

  Widget _buildStudentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.marginMobile, AppSizes.stackMd, AppSizes.marginMobile, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Siswa',
                style: AppTextStyle.headlineMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.onBackground),
              ),
              const SizedBox(height: 4),
              Text(
                'Cari dan pilih siswa untuk input poin',
                style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSizes.stackMd),
              SearchField(
                controller: _searchController,
                hint: 'Cari nama, kelas, atau jurusan...',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.stackMd),
        Expanded(
          child: _buildStudentList(),
        ),
      ],
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.users.limit(200).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('InputPoint student query error: ${snap.error}');
          return Center(
            child: Text('Gagal memuat data siswa',
                style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final List<_StudentItem> items = [];
        int ignoredDocs = 0;
        final Set<String> rolesFound = {};
        for (final doc in snap.data!.docs) {
          try {
            final raw = doc.data();
            if (raw is! Map<String, dynamic>) continue;
            final role = raw['role'];
            final name = (raw['name'] as String?) ?? '';
            final dept = raw['department'];
            rolesFound.add(role?.toString() ?? 'NULL');
            if (!isStudentRole(role) || name.isEmpty) {
              ignoredDocs++;
              continue;
            }
            debugPrint('DOC: role="$role" name="$name" dept="$dept"');
            items.add(_StudentItem(
              id: doc.id,
              name: (raw['name'] as String?) ?? '',
              className: (raw['className'] as String?) ?? (raw['class'] as String?) ?? '',
              department: normalizeDepartment(raw['department']),
              points: (raw['points'] as num?)?.toInt() ?? 0,
            ));
          } catch (_) {}
        }
        debugPrint('InputPoint: ${snap.data!.docs.length} users loaded, '
            '${items.length} students parsed, $ignoredDocs ignored');
        debugPrint('InputPoint: sample roles found: $rolesFound');

        List<_StudentItem> filtered = items;
        if (_searchQuery.isNotEmpty) {
          filtered = items.where((s) =>
            s.name.toLowerCase().contains(_searchQuery) ||
            s.className.toLowerCase().contains(_searchQuery) ||
            s.department.toLowerCase().contains(_searchQuery)
          ).toList();
        }

        if (filtered.isEmpty) {
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

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.marginMobile),
          children: filtered.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildStudentSelectorCard(item),
          )).toList(),
        );
      },
    );
  }

  Widget _buildStudentSelectorCard(_StudentItem item) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStudent = Student(
            id: item.id,
            name: item.name,
            nis: '',
            className: item.className,
            department: item.department,
            points: item.points,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSizes.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSizes.radius2xl),
          boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
        ),
        child: Row(
          children: [
            ProfileAvatar(name: item.name, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${item.className} \u2022 ${item.department}',
                      style: AppTextStyle.labelMd.copyWith(color: AppColors.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PointBadge(points: item.points),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentProfile(Student student) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
        boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Row(
        children: [
          ProfileAvatar(name: student.name, imageUrl: student.imageUrl, size: AppSizes.avatarXl),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name, style: AppTextStyle.titleLg.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(student.className, style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              ActivePointsBadge(points: student.points),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: 'Kategori Pelanggaran'),
        const SizedBox(height: 8),
        if (_selectedCategory != null)
          Container(
            padding: const EdgeInsets.all(AppSizes.cardPadding),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSizes.radius2xl),
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(_selectedCategory!.id,
                      style: AppTextStyle.headlineMd.copyWith(fontWeight: FontWeight.bold, color: AppColors.onPrimaryFixed)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedCategory!.name, style: AppTextStyle.titleLg.copyWith(color: AppColors.primary)),
                      Text('${_selectedCategory!.items.length} item pelanggaran', style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _categories.map((cat) {
            final isSel = cat.id == _selectedCategory?.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _selectedItem = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(color: isSel ? AppColors.primary : AppColors.outlineVariant),
                ),
                child: Text('${cat.id}: ${cat.name}',
                  style: AppTextStyle.labelLg.copyWith(color: isSel ? AppColors.onPrimary : AppColors.onSurfaceVariant)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildViolationItems() {
    if (_selectedCategory == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: 'Pilih Jenis Pelanggaran'),
        const SizedBox(height: 8),
        ..._selectedCategory!.items.map((item) {
          final isSel = _selectedItem?.id == item.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedItem = item),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                border: Border.all(
                  color: isSel ? AppColors.primary : AppColors.outlineVariant,
                  width: isSel ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSel ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: isSel ? AppColors.primary : AppColors.outline),
                    ),
                    child: isSel
                        ? const Icon(Icons.check, color: AppColors.onPrimary, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.id, style: AppTextStyle.labelLg.copyWith(color: AppColors.outline)),
                        const SizedBox(height: 2),
                        Text(item.description, style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurface)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PointBadge(points: item.points),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: 'Detail Kejadian (Opsional)'),
        const SizedBox(height: 8),
        CustomTextArea(
          controller: _detailController,
          hint: 'Berikan deskripsi singkat mengenai kejadian...',
          maxLines: 4,
          maxLength: 200,
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label: 'Tanggal Kejadian'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await AppDialog.pickDate(context, _selectedDate);
            if (date != null) {
              setState(() {
                _selectedDate = date;
                _updateDateLabel();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSizes.radius2xl),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: [BoxShadow(color: AppColors.shadowColor.withValues(alpha: 0.08), blurRadius: 20)],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(_dateLabel, style: AppTextStyle.bodyMd.copyWith(color: AppColors.onBackground)),
                const Spacer(),
                const Icon(Icons.expand_more, color: AppColors.outline),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: () async {
        if (_selectedCategory == null || _selectedItem == null || _selectedStudent == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih kategori dan jenis pelanggaran terlebih dahulu')),
          );
          return;
        }

        await FirebaseService.violations.add({
          'studentId': _selectedStudent!.id,
          'studentName': _selectedStudent!.name,
          'category': _selectedCategory!.name,
          'violation': _selectedItem!.description,
          'points': _selectedItem!.points,
          'description': _detailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        await FirebaseService.users.doc(_selectedStudent!.id).update({
          'points': FieldValue.increment(_selectedItem!.points),
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Poin berhasil disimpan'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd]),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save, color: AppColors.onPrimary),
            const SizedBox(width: 8),
            Text('Simpan Poin', style: AppTextStyle.titleLg.copyWith(color: AppColors.onPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Center(
      child: Text(
        'Perubahan ini akan dicatat secara permanen di buku disiplin digital.',
        style: AppTextStyle.labelMd.copyWith(color: AppColors.outline, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavBar(
      currentIndex: _currentNav,
      items: const [
        NavItem(icon: Icons.dashboard, label: 'Dashboard', route: '/admin/dashboard'),
        NavItem(icon: Icons.psychology, label: 'Counseling', route: '/admin/counseling'),
        NavItem(icon: Icons.assignment, label: 'Reports', route: '/admin/reports'),
      ],
      onTap: (i) => setState(() => _currentNav = i),
    );
  }
}

class _StudentItem {
  final String id;
  final String name;
  final String className;
  final String department;
  final int points;

  const _StudentItem({
    required this.id,
    required this.name,
    required this.className,
    required this.department,
    required this.points,
  });
}
