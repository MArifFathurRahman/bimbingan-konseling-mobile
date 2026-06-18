import 'package:flutter/material.dart';

import '../models/student_model.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentService _service = StudentService();
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  String _searchQuery = '';
  String _selectedDepartment = 'Semua';
  bool _isLoading = false;

  List<Student> get students => _filteredStudents.isEmpty ? _students : _filteredStudents;
  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _service.init();
    _students = _service.getStudents();
    _filteredStudents = List.from(_students);
    _isLoading = false;
    notifyListeners();
  }

  List<Student> getStudentsByClass(String className) =>
      _service.getStudentsByClass(className);

  Student? getStudentById(String id) => _service.getStudentById(id);

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByDepartment(String dept) {
    _selectedDepartment = dept;
    _applyFilters();
  }

  void _applyFilters() {
    var result = List<Student>.from(_students);
    if (_selectedDepartment != 'Semua') {
      result = result.where((s) => s.department == _selectedDepartment).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result.where((s) =>
        s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.nis.contains(_searchQuery)
      ).toList();
    }
    _filteredStudents = result;
    notifyListeners();
  }

  Future<void> addPoints(String studentId, int points) async {
    await _service.addPoints(studentId, points);
    final idx = _students.indexWhere((s) => s.id == studentId);
    if (idx != -1) {
      _students[idx] = _students[idx].copyWith(
        points: _students[idx].points + points,
      );
    }
    _applyFilters();
  }

  List<String> getDepartments() => _service.getDepartments();
  List<String> getClasses() => _service.getClasses();
}
