import 'package:flutter/foundation.dart';

import '../core/utils/student_helper.dart';
import '../models/student_model.dart';
import 'firebase_service.dart';

class StudentService {
  List<Student> _students = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final snapshot = await FirebaseService.users
          .limit(500)
          .get()
          .timeout(const Duration(seconds: 10));
      debugPrint('StudentService: query returned ${snapshot.docs.length} docs');
      _students = [];
      int ignoredDocs = 0;
      final Set<String> rolesFound = {};
      for (final doc in snapshot.docs) {
        try {
          final raw = doc.data();
          if (raw is! Map<String, dynamic>) {
            debugPrint('StudentService: doc ${doc.id} has non-map data');
            continue;
          }
          final role = raw['role'];
          final name = raw['name'] as String? ?? '';
          rolesFound.add(role.toString());
          debugPrint('DOC: role="$role" name="$name" dept="${raw['department']}"');
          if (!isStudentRole(role) || name.isEmpty) {
            ignoredDocs++;
            continue;
          }
          final student = Student.fromJson({...raw, 'id': doc.id});
          _students.add(student);
        } catch (e) {
          debugPrint('StudentService: skipping doc ${doc.id} — $e');
        }
      }
      debugPrint('StudentService: ${snapshot.docs.length} users loaded, '
          '${_students.length} students parsed, $ignoredDocs ignored');
      debugPrint('StudentService: sample roles found: $rolesFound');
    } catch (e) {
      debugPrint('StudentService: query failed — $e');
      _students = [];
    }
    _initialized = true;
  }

  Future<void> refresh() async {
    _initialized = false;
    await init();
  }

  List<Student> getStudents() => _students;
  List<Student> getStudentsByDepartment(String dept) =>
      _students.where((s) => s.department == dept).toList();
  List<Student> getStudentsByClass(String className) =>
      _students.where((s) => s.className == className).toList();
  List<Student> searchStudents(String query) {
    if (query.isEmpty) return _students;
    return _students.where((s) =>
      s.name.toLowerCase().contains(query.toLowerCase()) ||
      s.nis.contains(query) ||
      s.className.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
  Student? getStudentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addPoints(String studentId, int points, {String? reason}) async {
    final idx = _students.indexWhere((s) => s.id == studentId);
    if (idx == -1) return;
    final newPoints = _students[idx].points + points;
    try {
      await FirebaseService.users
          .doc(studentId)
          .update({'points': newPoints})
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Firestore unavailable — update local only
    }
    _students[idx] = _students[idx].copyWith(points: newPoints);
  }

  List<String> getDepartments() =>
      _students.map((s) => s.department).toSet().toList();
  List<String> getClasses() =>
      _students.map((s) => s.className).toSet().toList();
  List<Student> getTopStudents(int limit) {
    final sorted = List<Student>.from(_students)
      ..sort((a, b) => a.points.compareTo(b.points));
    return sorted.take(limit).toList();
  }
  List<Student> getWarningStudents() =>
      _students.where((s) => s.points >= 25).toList();
}
