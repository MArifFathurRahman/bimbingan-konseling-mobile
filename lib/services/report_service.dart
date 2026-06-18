import '../models/report_model.dart';
import 'firebase_service.dart';

class ReportService {
  List<Report> _reports = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final snapshot = await FirebaseService.reports
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 5));
      _reports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Report.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (_) {
      _reports = [];
    }
    _initialized = true;
  }

  List<Report> getReports() => List.unmodifiable(_reports);

  List<Report> getReportsByStudent(String studentId) =>
      _reports.where((r) => r.studentId == studentId).toList();

  Future<void> addReport(Report report) async {
    try {
      await FirebaseService.reports.add(report.toJson());
    } catch (_) {
      // Firestore unavailable
    }
    _reports.insert(0, report);
  }
}
