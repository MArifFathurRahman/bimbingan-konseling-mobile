import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_textstyle.dart';
import '../../core/themes/app_theme.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/pdf_service.dart';
import 'package:printing/printing.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/point_badge.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/status_badge.dart';

class StudentDetailMonitoringPage extends StatelessWidget {
  final Student student;

  const StudentDetailMonitoringPage({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(student.name, style: AppTextStyle.titleLg.copyWith(color: AppColors.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
            tooltip: 'Export PDF',
            onPressed: () => _exportPdf(context, student),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileCard(student: student),
          const SizedBox(height: 24),
          _ViolationHistorySection(student: student),
          const SizedBox(height: 24),
          _RecommendationSection(student: student),
          const SizedBox(height: 24),
          _CounselButton(student: student),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Student student;
  const _ProfileCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseService.userDoc(student.id).snapshots(),
      builder: (context, userSnap) {
        final points = userSnap.hasData && userSnap.data!.exists
            ? ((userSnap.data!.data() as Map<String, dynamic>)['points'] as num?)?.toInt() ?? student.points
            : student.points;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(name: student.name, imageUrl: student.imageUrl, size: AppSizes.avatarLg),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.bold),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text('${student.className} \u2022 ${student.department}',
                        style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('NIS: ${student.nis}',
                        style: AppTextStyle.labelLg.copyWith(color: AppColors.outline),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        PointBadge(points: points),
                        if (student.status == 'Aktif')
                          StatusBadge.aktif()
                        else if (student.status == 'Peringatan')
                          StatusBadge.peringatan()
                        else
                          StatusBadge.safe(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ViolationHistorySection extends StatefulWidget {
  final Student student;
  const _ViolationHistorySection({required this.student});

  @override
  State<_ViolationHistorySection> createState() => _ViolationHistorySectionState();
}

class _ViolationHistorySectionState extends State<_ViolationHistorySection> {
  int _currentPoints = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseService.violations
          .where('studentId', isEqualTo: widget.student.id)
          .snapshots(),
      builder: (context, violationSnap) {
        if (violationSnap.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Center(
              child: Text('Gagal memuat data pelanggaran',
                  style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            ),
          );
        }

        if (!violationSnap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = violationSnap.data!.docs;
        final sorted = List<QueryDocumentSnapshot>.from(docs);
        sorted.sort((a, b) {
          final aTime = ((a.data() as Map<String, dynamic>)['createdAt']);
          final bTime = ((b.data() as Map<String, dynamic>)['createdAt']);
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        final violationCount = sorted.length;

        return Column(
          children: [
            _StatsRow(points: _currentPoints, violationCount: violationCount),
            const SizedBox(height: 24),
            _buildSectionTitle('Riwayat Pelanggaran'),
            const SizedBox(height: 16),
            _ViolationList(violations: sorted),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 24, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyle.titleLg.copyWith(color: AppColors.onSurface)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int points;
  final int violationCount;
  const _StatsRow({required this.points, required this.violationCount});

  String _getRank(int p) {
    if (p >= 50) return 'Rendah';
    if (p >= 25) return 'Sedang';
    if (p >= 11) return 'Baik';
    return 'Sangat Baik';
  }

  Color _getRankColor(int p) {
    if (p >= 50) return AppColors.error;
    if (p >= 25) return AppColors.yellow;
    if (p >= 11) return AppColors.secondary;
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Total Poin', '$points', AppColors.error)),
          Container(width: 1, height: 48, color: AppColors.outlineVariant),
          Expanded(child: _buildStatItem('Pelanggaran', '$violationCount', AppColors.yellow)),
          Container(width: 1, height: 48, color: AppColors.outlineVariant),
          Expanded(child: _buildStatItem('Peringkat', _getRank(points), _getRankColor(points))),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyle.titleLg.copyWith(color: color, fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyle.labelMd.copyWith(color: AppColors.onSurfaceVariant),
            maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      ],
    );
  }
}

class _ViolationList extends StatelessWidget {
  final List<QueryDocumentSnapshot> violations;
  const _ViolationList({required this.violations});

  @override
  Widget build(BuildContext context) {
    if (violations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Text('Belum ada catatan pelanggaran',
              style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
        ),
      );
    }

    return Column(
      children: violations.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final catName = (data['category'] as String?) ?? (data['categoryName'] as String?) ?? '';
        final violationDesc = (data['violation'] as String?) ?? (data['violationDescription'] as String?) ?? '';
        final pts = (data['points'] as num?)?.toInt() ?? 0;
        final date = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();
        final recordedBy = (data['recordedBy'] as String?) ?? '';
        final catColor = _getCategoryColor(catName);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: const Border(left: BorderSide(color: AppColors.error, width: 4)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(catName, style: AppTextStyle.labelMd.copyWith(color: catColor, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  Text('$pts pts', style: AppTextStyle.titleLg.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(violationDesc, style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text(_formatDate(date), style: AppTextStyle.labelMd.copyWith(color: AppColors.outline)),
                  if (recordedBy.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.person_outline, size: 12, color: AppColors.outline),
                    const SizedBox(width: 4),
                    Text(recordedBy, style: AppTextStyle.labelMd.copyWith(color: AppColors.outline)),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Keterlambatan': return const Color(0xFFeab308);
      case 'Kehadiran': return Colors.orange;
      case 'Pakaian': return AppColors.secondary;
      case 'Kepribadian': return Colors.deepPurple;
      case 'Merokok': return AppColors.error;
      default: return AppColors.primary;
    }
  }
}

class _RecommendationSection extends StatelessWidget {
  final Student student;
  const _RecommendationSection({required this.student});

  String _getRecommendation(int points) {
    if (points >= 100) return 'Siswa memerlukan konseling intensif dan pemanggilan orang tua. Poin sangat tinggi, risiko dikeluarkan.';
    if (points >= 50) return 'Siswa perlu konseling segera. Poin sudah masuk kategori berbahaya, perlu pembinaan khusus.';
    if (points >= 25) return 'Siswa perlu perhatian lebih. Disarankan konseling rutin untuk mencegah peningkatan poin.';
    if (points >= 11) return 'Siswa dalam pengawasan. Berikan pengarahan dan motivasi untuk memperbaiki perilaku.';
    return 'Siswa dalam kondisi baik. Pertahankan prestasi dan perilaku positif.';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseService.userDoc(student.id).snapshots(),
      builder: (context, userSnap) {
        final points = userSnap.hasData && userSnap.data!.exists
            ? ((userSnap.data!.data() as Map<String, dynamic>)['points'] as num?)?.toInt() ?? student.points
            : student.points;
        final recommendation = _getRecommendation(points);
        final isWarning = points >= 25;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isWarning ? AppColors.errorContainer.withValues(alpha: 0.15) : AppColors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isWarning ? AppColors.error.withValues(alpha: 0.2) : AppColors.green.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isWarning ? AppColors.error.withValues(alpha: 0.1) : AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isWarning ? Icons.priority_high : Icons.check_circle,
                    color: isWarning ? AppColors.error : AppColors.green, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isWarning ? 'PERLU PERHATIAN' : 'BAIK',
                        style: AppTextStyle.labelLg.copyWith(fontWeight: FontWeight.bold,
                            color: isWarning ? AppColors.error : AppColors.green, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(recommendation,
                        style: AppTextStyle.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CounselButton extends StatelessWidget {
  final Student student;
  const _CounselButton({required this.student});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        title: 'Konseling',
        icon: Icons.chat_bubble_outline,
        onTap: () async {
          final auth = context.read<AuthProvider>();
          final teacher = auth.user;
          if (teacher == null) return;

          await FirebaseService.counselingRequests.add({
            'studentId': student.id,
            'studentName': student.name,
            'studentClass': student.className,
            'requestedBy': teacher.id,
            'requestedByName': teacher.name,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'notes': '',
          });

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Rekomendasi konseling telah dikirim ke BK'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _exportPdf(BuildContext context, Student student) async {
  try {
    final snap = await FirebaseService.violations
        .where('studentId', isEqualTo: student.id)
        .get();
    final violations = snap.docs.map((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final date = d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now();
      const months = ['Januari', 'Februari', 'Maret', 'April', 'Mai', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return <String, dynamic>{
        'date': '${date.day} ${months[date.month - 1]} ${date.year}',
        'category': (d['category'] as String?) ?? (d['categoryName'] as String?) ?? '-',
        'description': (d['violation'] as String?) ?? (d['violationDescription'] as String?) ?? '-',
        'points': (d['points'] as num?)?.toInt() ?? 0,
      };
    }).toList();
    final totalPoints = violations.fold<int>(0, (s, v) => s + (v['points'] as int));
    final bytes = await PdfService.generateStudentReport(
      student: student,
      totalPoints: totalPoints,
      violationCount: violations.length,
      violations: violations,
    );
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'Laporan_Pelanggaran_${student.name}',
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal export PDF: $e')),
    );
  }
}
