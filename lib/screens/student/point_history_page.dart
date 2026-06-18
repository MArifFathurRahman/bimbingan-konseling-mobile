import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/pdf_service.dart';
import 'package:printing/printing.dart';

class PointHistoryPage extends StatefulWidget {
  const PointHistoryPage({super.key});

  @override
  State<PointHistoryPage> createState() => _PointHistoryPageState();
}

class _PointHistoryPageState extends State<PointHistoryPage> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Point History',
          style: AppTextStyle.titleLg.copyWith(color: AppColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
            tooltip: 'Export PDF',
            onPressed: () => _exportMyPdf(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseService.userDoc(userId).snapshots(),
        builder: (context, userSnap) {
          final totalPoints = userSnap.hasData && userSnap.data!.exists
              ? ((userSnap.data!.data() as Map<String, dynamic>)['points'] as num?)?.toInt() ?? 0
              : 0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseService.violations
                .where('studentId', isEqualTo: userId)
                .snapshots(),
            builder: (context, violationSnap) {
              final hasError = violationSnap.hasError || userSnap.hasError;
              final hasData = violationSnap.hasData;
              final docs = violationSnap.data?.docs ?? [];
              final sorted = List<QueryDocumentSnapshot>.from(docs);
              sorted.sort((a, b) {
                final aTime = ((a.data() as Map<String, dynamic>)['createdAt']);
                final bTime = ((b.data() as Map<String, dynamic>)['createdAt']);
                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }
                return 0;
              });

              if (hasError) {
                return ListView(
                  padding: const EdgeInsets.all(AppSizes.marginMobile),
                  children: [
                    Center(
                      child: Text(
                        'Gagal memuat data',
                        style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                );
              }

              final filtered = sorted.where((doc) {
                if (_selectedFilter == 'Semua') return true;
                final pts = ((doc.data() as Map<String, dynamic>)['points'] as num?)?.toInt() ?? 0;
                return _selectedFilter == 'Poin Masuk' ? pts == 0 : pts > 0;
              }).toList();

              final totalViolationPoints = sorted.fold<int>(0, (sum, doc) {
                return sum + (((doc.data() as Map<String, dynamic>)['points'] as num?)?.toInt() ?? 0);
              });

              return ListView(
                padding: const EdgeInsets.all(AppSizes.marginMobile),
                children: [
                  _buildSafetyScore(totalPoints),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildSummaryRow(totalPoints, docs.length, totalViolationPoints),
                  const SizedBox(height: AppSizes.stackLg),
                  _buildFilterTabs(),
                  const SizedBox(height: AppSizes.stackMd),
                  if (!hasData)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (filtered.isEmpty)
                    _emptyState('Tidak ada riwayat')
                  else
                    ...filtered.map((doc) => _buildTimelineEntry(doc)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSafetyScore(int totalPoints) {
    final status = _getStatus(totalPoints);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandGradientStart, AppColors.brandGradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radius2xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAFETY SCORE',
                  style: AppTextStyle.labelLg.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.8),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalPoints pts',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'Aman' ? Icons.check_circle :
                  status == 'Perhatian' ? Icons.info :
                  status == 'Risiko' ? Icons.warning :
                  Icons.dangerous,
                  color: status == 'Aman' ? AppColors.green :
                         status == 'Perhatian' ? AppColors.yellow :
                         status == 'Risiko' ? AppColors.yellow :
                         AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 6),
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

  Widget _buildSummaryRow(int totalPoints, int violationCount, int totalViolationPoints) {
    return Row(
      children: [
        _buildSummaryCard('Total Poin', '$totalPoints', AppColors.primary),
        const SizedBox(width: 12),
        _buildSummaryCard('Pelanggaran', '$violationCount', AppColors.error),
        const SizedBox(width: 12),
        _buildSummaryCard('Beban Poin', '$totalViolationPoints', AppColors.yellow),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyle.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['Semua', 'Poin Masuk', 'Poin Keluar'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final active = f == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: active ? null : Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  f,
                  style: AppTextStyle.labelLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimelineEntry(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final violationDesc = (data['violation'] as String?) ?? (data['violationDescription'] as String?) ?? '';
    final pts = (data['points'] as num?)?.toInt() ?? 0;
    final catName = (data['category'] as String?) ?? (data['categoryName'] as String?) ?? '';
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final isViolation = pts > 0;
    final label = violationDesc.isNotEmpty ? violationDesc : catName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isViolation ? AppColors.error : AppColors.green).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
            child: Icon(
              isViolation ? Icons.warning : Icons.check_circle,
              color: isViolation ? AppColors.error : AppColors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyle.bodyMd.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(createdAt),
                  style: AppTextStyle.labelMd.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
          Text(
            isViolation ? '+$pts' : '+0',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isViolation ? AppColors.error : AppColors.green,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: AppColors.outlineVariant),
            const SizedBox(height: 12),
            Text(message, style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  String _getStatus(int points) {
    if (points <= 20) return 'Aman';
    if (points <= 50) return 'Perhatian';
    if (points <= 80) return 'Risiko';
    return 'Bahaya';
  }

  Future<void> _exportMyPdf(BuildContext context) async {
    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.id ?? '';
      final name = auth.user?.name ?? 'Siswa';

      final userDoc = await FirebaseService.userDoc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final className = (userData['className'] as String?) ?? (userData['class'] as String?) ?? '';
      final dept = (userData['department'] as String?) ?? '';
      final nis = (userData['nis'] as String?) ?? '';
      final points = (userData['points'] as num?)?.toInt() ?? 0;

      final snap = await FirebaseService.violations
          .where('studentId', isEqualTo: userId)
          .get();
      final violations = snap.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final date = d['createdAt'] != null
            ? (d['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        return <String, dynamic>{
          'date': '${date.day} ${_months[date.month - 1]} ${date.year}',
          'category': (d['category'] as String?) ?? (d['categoryName'] as String?) ?? '-',
          'description': (d['violation'] as String?) ?? (d['violationDescription'] as String?) ?? '-',
          'points': (d['points'] as num?)?.toInt() ?? 0,
        };
      }).toList();

      final student = Student(
        id: userId,
        name: name,
        nis: nis,
        className: className,
        department: dept,
        points: points,
      );

      final bytes = await PdfService.generateStudentReport(
        student: student,
        totalPoints: points,
        violationCount: violations.length,
        violations: violations,
      );
      await Printing.layoutPdf(
        onLayout: (_) => bytes,
        name: 'Laporan_Pelanggaran_$name',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export PDF: $e')),
      );
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
}
