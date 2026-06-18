import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/student_model.dart';

class PdfService {
  static const _schoolName = 'BINUSA SafeSpace';
  static final _primaryColor = PdfColor.fromInt(0xFF1E3A5F);
  static final _accentColor = PdfColor.fromInt(0xFF22c55e);

  static Future<Uint8List> generateStudentReport({
    required Student student,
    required int totalPoints,
    required int violationCount,
    required List<Map<String, dynamic>> violations,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Laporan Pelanggaran Siswa'),
        footer: (context) => _buildFooter(),
        build: (context) => [
          _buildStudentInfo(student, totalPoints, violationCount),
          pw.SizedBox(height: 20),
          _buildViolationTable(violations),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateSummonLetter({
    required Student student,
    required String reason,
    required DateTime date,
    required String location,
    required List<Map<String, dynamic>> violations,
  }) async {
    final doc = pw.Document();

    Uint8List? logoBytes;
    try {
      final data = await rootBundle.load('assets/images/binusa_logo.png');
      logoBytes = data.buffer.asUint8List();
    } catch (_) {
      logoBytes = null;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildFormalHeader(logoBytes),
        footer: (context) => _buildFormalFooter(),
        build: (context) => [
          _buildSummonContent(student, reason, date, location, violations),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              _schoolName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Sistem Informasi Bimbingan Konseling',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(thickness: 2, color: _primaryColor),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildFormalHeader(Uint8List? logoBytes) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoBytes != null)
              pw.Image(pw.MemoryImage(logoBytes), width: 50, height: 50),
            if (logoBytes != null) pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'SMK BINTANG NUSANTARA',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Jl. Jombang Raya No.15, Pd. Kacang Tim., Kec. Pd. Aren, Kota Tangerang Selatan, Banten 15227',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Telp:  (021)74864847 | Email: humas@albin.sch.id | Web: https://s.id/smkbintangnusantara',
                    style: pw.TextStyle(fontSize: 7, color: PdfColors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 2, color: _primaryColor),
        pw.SizedBox(height: 1),
        pw.Container(height: 0.5, color: _primaryColor),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dicetak: ${DateTime.now().toString().substring(0, 16)}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
            pw.Text(
              'SMK BINUSA \u2022 Sistem Informasi BK',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFormalFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Dokumen resmi SMK BINUSA',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey),
            ),
            pw.Text(
              'Dicetak: ${DateTime.now().toString().substring(0, 16)}',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStudentInfo(
    Student student,
    int totalPoints,
    int violationCount,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _infoRow('Nama Siswa', student.name),
          _infoRow('Kelas', student.className),
          _infoRow('Jurusan', student.department),
          _infoRow('NIS', student.nis),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1, color: PdfColors.grey200),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _infoBadge('Total Poin', '$totalPoints', _primaryColor),
              pw.SizedBox(width: 16),
              _infoBadge('Pelanggaran', '$violationCount', _accentColor),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(': $value', style: pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _infoBadge(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildViolationTable(List<Map<String, dynamic>> violations) {
    if (violations.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'Tidak ada catatan pelanggaran',
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey),
        ),
      );
    }

    final headers = ['No', 'Tanggal', 'Kategori', 'Pelanggaran', 'Poin'];
    final widths = <double>[24, 80, 60, 220, 36];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: List.generate(headers.length, (i) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              child: pw.Text(
                headers[i],
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }),
        ),
        ...violations.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          return pw.TableRow(
            children: [
              _cell('${i + 1}', widths[0]),
              _cell(v['date'] as String? ?? '-', widths[1]),
              _cell(v['category'] as String? ?? '-', widths[2]),
              _cell(v['description'] as String? ?? '-', widths[3]),
              _cell('${v['points'] as int? ?? 0}', widths[4]),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(String text, double width) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildSummonContent(
    Student student,
    String reason,
    DateTime date,
    String location,
    List<Map<String, dynamic>> violations,
  ) {
    final totalPoints = violations.fold<int>(
      0,
      (s, v) => s + ((v['points'] as int?) ?? 0),
    );
    const letterNumber = '421/SMKBINUSA/XII/2024';
    const attachment = '-';
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.SizedBox(width: 60, child: pw.Text('Nomor', style: _fieldStyle)),
            pw.Text(': $letterNumber', style: _valueStyle),
          ],
        ),
        pw.Row(
          children: [
            pw.SizedBox(
              width: 60,
              child: pw.Text('Lampiran', style: _fieldStyle),
            ),
            pw.Text(': $attachment', style: _valueStyle),
          ],
        ),
        pw.Row(
          children: [
            pw.SizedBox(
              width: 60,
              child: pw.Text('Perihal', style: _fieldStyle),
            ),
            pw.Text(': Panggilan Orang Tua/Wali', style: _valueStyle),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Kepada Yth.', style: pw.TextStyle(fontSize: 11)),
        pw.Text(
          'Bapak/Ibu Orang Tua/Wali Murid',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          '${student.name} - ${student.className}',
          style: pw.TextStyle(fontSize: 11),
        ),
        pw.Text('di Tempat', style: pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 16),
        pw.Text('Dengan hormat,', style: pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 10),
        pw.Paragraph(
          text:
              'Sehubungan dengan adanya pelanggaran tata tertib yang dilakukan oleh '
              'anak Bapak/Ibu, dengan ini kami mengundang untuk hadir pada:',
          style: pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Nama Siswa', student.name),
              _buildDetailRow(
                'Kelas / Jurusan',
                '${student.className} / ${student.department}',
              ),
              _buildDetailRow('NIS', student.nis),
              _buildDetailRow('Total Poin Pelanggaran', '$totalPoints Poin'),
              _buildDetailRow(
                'Jumlah Pelanggaran',
                '${violations.length} Kali',
              ),
              _buildDetailRow('Alasan Pemanggilan', reason),
              _buildDetailRow('Hari / Tanggal', dateStr),
              _buildDetailRow('Waktu', 'Pukul 09.00 WIB'),
              _buildDetailRow('Tempat', location),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Paragraph(
          text:
              'Mohon kesediaan Bapak/Ibu untuk hadir tepat waktu. '
              'Kehadiran Bapak/Ibu sangat diharapkan demi pembinaan dan '
              'perkembangan putra/putri Bapak/Ibu.',
          style: pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
        ),
        pw.SizedBox(height: 4),
        pw.Paragraph(
          text:
              'Demikian surat panggilan ini disampaikan. Atas perhatian dan '
              'kerjasama Bapak/Ibu, kami ucapkan terima kasih.',
          style: pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Tangerang Selatan, $dateStr',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Kepala Sekolah,', style: pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Nurhadi, S.Pd.I, M.M',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(': $value', style: pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.TextStyle get _fieldStyle =>
      pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

  static pw.TextStyle get _valueStyle => pw.TextStyle(fontSize: 10);
}
