import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/violation_model.dart';
import 'firebase_service.dart';

class ViolationService {
  static const List<ViolationCategory> categories = [
    ViolationCategory(id: 'A', name: 'Keterlambatan', items: [
      ViolationItem(id: 'A1', description: 'Terlambat > 15 menit tanpa izin', points: 3),
      ViolationItem(id: 'A2', description: 'Terlambat > 15 menit sudah izin', points: 2),
    ]),
    ViolationCategory(id: 'B', name: 'Kehadiran', items: [
      ViolationItem(id: 'B1', description: 'Tidak masuk tanpa izin / alpa', points: 7),
      ViolationItem(id: 'B2', description: 'Tidak masuk menggunakan keterangan palsu', points: 10),
      ViolationItem(id: 'B3', description: 'Meninggalkan KBM tanpa izin guru', points: 5),
      ViolationItem(id: 'B4', description: 'Meninggalkan KBM dan tidak kembali', points: 5),
      ViolationItem(id: 'B5', description: 'Tidak mengikuti upacara', points: 5),
      ViolationItem(id: 'B6', description: 'Tidak membawa Al Qur\'an / tadarus', points: 5),
      ViolationItem(id: 'B7', description: 'Tidak mengikuti sholat dhuha', points: 5),
      ViolationItem(id: 'B8', description: 'Tidak mengikuti sholat jum\'at (laki-laki)', points: 5),
    ]),
    ViolationCategory(id: 'C', name: 'Pakaian', items: [
      ViolationItem(id: 'C1', description: 'Seragam tidak sesuai aturan', points: 7),
      ViolationItem(id: 'C2', description: 'Tidak memakai atribut sekolah', points: 10),
      ViolationItem(id: 'C3', description: 'Sepatu selain hitam tanpa izin', points: 5),
      ViolationItem(id: 'C4', description: 'Memakai jaket di kelas tanpa izin', points: 5),
    ]),
    ViolationCategory(id: 'D', name: 'Merokok', items: [
      ViolationItem(id: 'D1', description: 'Membawa rokok', points: 25),
      ViolationItem(id: 'D2', description: 'Merokok di lingkungan sekolah', points: 50),
    ]),
    ViolationCategory(id: 'E', name: 'Senjata Tajam', items: [
      ViolationItem(id: 'E1', description: 'Membawa senjata tajam tanpa izin', points: 35),
      ViolationItem(id: 'E2', description: 'Membawa senjata untuk mengancam', points: 50),
    ]),
    ViolationCategory(id: 'F', name: 'Kepribadian', items: [
      ViolationItem(id: 'F1', description: 'Berhias berlebihan / aksesoris (laki-laki)', points: 5),
      ViolationItem(id: 'F2', description: 'Perhiasan emas tidak sesuai aturan', points: 5),
      ViolationItem(id: 'F3', description: 'Rambut tidak rapih', points: 5),
      ViolationItem(id: 'F4', description: 'Mewarnai rambut', points: 10),
      ViolationItem(id: 'F5', description: 'Berkata kasar sesama siswa', points: 5),
      ViolationItem(id: 'F6', description: 'Berkata kasar pada guru', points: 10),
      ViolationItem(id: 'F7', description: 'Berkelahi antar siswa', points: 50),
      ViolationItem(id: 'F8', description: 'Berkelahi dengan guru / pegawai', points: 80),
      ViolationItem(id: 'F9', description: 'Berkelahi dengan siswa sekolah lain', points: 50),
      ViolationItem(id: 'F10', description: 'Provokator perkelahian', points: 50),
    ]),
    ViolationCategory(id: 'G', name: 'Ketertiban', items: [
      ViolationItem(id: 'G1', description: 'Mengotori / corat-coret inventaris sekolah', points: 15),
      ViolationItem(id: 'G2', description: 'Merusak benda milik sekolah / guru', points: 15),
      ViolationItem(id: 'G3', description: 'Membuang sampah sembarangan', points: 5),
      ViolationItem(id: 'G4', description: 'Melompat pagar sekolah', points: 10),
      ViolationItem(id: 'G5', description: 'Acara organisasi luar tanpa izin', points: 20),
      ViolationItem(id: 'G6', description: 'HP aktif saat KBM / tadarus', points: 10),
      ViolationItem(id: 'G7', description: 'Berpacaran di lingkungan sekolah', points: 25),
    ]),
    ViolationCategory(id: 'H', name: 'Ancaman', items: [
      ViolationItem(id: 'H1', description: 'Mengancam antar siswa', points: 50),
      ViolationItem(id: 'H2', description: 'Mengancam guru / karyawan', points: 80),
    ]),
    ViolationCategory(id: 'I', name: 'Narkoba', items: [
      ViolationItem(id: 'I1', description: 'Penggunaan / membawa / mengedar narkoba', points: 100),
    ]),
    ViolationCategory(id: 'J', name: 'Pornografi', items: [
      ViolationItem(id: 'J1', description: 'Membawa materi pornografi', points: 50),
      ViolationItem(id: 'J2', description: 'Menonton video porno di sekolah', points: 50),
    ]),
    ViolationCategory(id: 'K', name: 'Perbuatan Asusila', items: [
      ViolationItem(id: 'K1', description: 'Pemerasan / pencurian / jambret', points: 100),
      ViolationItem(id: 'K2', description: 'Pemerkosaan / hamil di luar nikah', points: 100),
    ]),
  ];

  List<ViolationRecord> _records = [];
  List<SummonsRecord> _summons = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Future.wait([
      _loadRecords(),
      _loadSummons(),
    ]);
    _initialized = true;
  }

  Future<void> _loadRecords() async {
    try {
      final snapshot = await FirebaseService.violations
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 5));
      _records = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ViolationRecord(
          id: doc.id,
          studentId: (data['studentId'] as String?) ?? '',
          studentName: (data['studentName'] as String?) ?? '',
          categoryId: (data['categoryId'] as String?) ?? '',
          categoryName: (data['categoryName'] as String?) ?? '',
          violationId: (data['violationId'] as String?) ?? '',
          violationDescription: (data['violationDescription'] as String?) ?? '',
          points: (data['points'] as num?)?.toInt() ?? 0,
          date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
          note: data['note'] as String?,
          recordedBy: (data['recordedBy'] as String?) ?? '',
        );
      }).toList();
    } catch (_) {
      _records = [];
    }
  }

  Future<void> _loadSummons() async {
    try {
      final snapshot = await FirebaseService.summons
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 5));
      _summons = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SummonsRecord(
          id: doc.id,
          studentId: (data['studentId'] as String?) ?? '',
          studentName: (data['studentName'] as String?) ?? '',
          reason: (data['reason'] as String?) ?? '',
          date: data['date'] != null ? (data['date'] as Timestamp).toDate() : DateTime.now(),
          time: (data['time'] as String?) ?? '',
          location: (data['location'] as String?) ?? 'Ruang Bimbingan Konseling',
          status: (data['status'] as String?) ?? 'sent',
        );
      }).toList();
    } catch (_) {
      _summons = [];
    }
  }

  List<ViolationCategory> getCategories() => categories;
  ViolationCategory? getCategory(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
  List<ViolationRecord> getRecords() => List.unmodifiable(_records);
  List<ViolationRecord> getRecordsByStudent(String studentId) =>
      _records.where((r) => r.studentId == studentId).toList();
  List<ViolationRecord> getRecentRecords({int limit = 10}) {
    final sorted = List<ViolationRecord>.from(_records)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }
  int getTotalPointsByStudent(String studentId) {
    return _records
        .where((r) => r.studentId == studentId)
        .fold<int>(0, (sum, r) => sum + r.points);
  }

  Future<void> addRecord(ViolationRecord record) async {
    try {
      final docRef = await FirebaseService.violations.add({
        'studentId': record.studentId,
        'studentName': record.studentName,
        'categoryId': record.categoryId,
        'categoryName': record.categoryName,
        'violationId': record.violationId,
        'violationDescription': record.violationDescription,
        'points': record.points,
        'date': Timestamp.fromDate(record.date),
        'note': record.note,
        'recordedBy': record.recordedBy,
      });
      _records.insert(0, ViolationRecord(
        id: docRef.id,
        studentId: record.studentId,
        studentName: record.studentName,
        categoryId: record.categoryId,
        categoryName: record.categoryName,
        violationId: record.violationId,
        violationDescription: record.violationDescription,
        points: record.points,
        date: record.date,
        note: record.note,
        recordedBy: record.recordedBy,
      ));
    } catch (_) {
      // Firestore unavailable — keep local
      _records.insert(0, record);
    }
  }

  List<SummonsRecord> getSummons() => List.unmodifiable(_summons);
  List<SummonsRecord> getSummonsByStudent(String studentId) =>
      _summons.where((s) => s.studentId == studentId).toList();

  Future<void> addSummons(SummonsRecord summons) async {
    try {
      await FirebaseService.summons.add({
        'studentId': summons.studentId,
        'studentName': summons.studentName,
        'reason': summons.reason,
        'date': Timestamp.fromDate(summons.date),
        'time': summons.time,
        'location': summons.location,
        'status': summons.status,
      });
    } catch (_) {
      // Firestore unavailable
    }
    _summons.insert(0, summons);
  }
}
