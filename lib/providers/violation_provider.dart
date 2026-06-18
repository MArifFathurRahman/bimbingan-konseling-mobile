import 'package:flutter/material.dart';

import '../models/violation_model.dart';
import '../services/violation_service.dart';

class ViolationProvider extends ChangeNotifier {
  final ViolationService _service = ViolationService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<ViolationCategory> get categories => _service.getCategories();
  List<ViolationRecord> get records => _service.getRecords();
  List<SummonsRecord> get summons => _service.getSummons();

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    await _service.init();
    _isLoading = false;
    notifyListeners();
  }

  ViolationCategory? getCategory(String id) => _service.getCategory(id);
  List<ViolationRecord> getRecordsByStudent(String id) =>
      _service.getRecordsByStudent(id);
  List<ViolationRecord> getRecentRecords({int limit = 10}) =>
      _service.getRecentRecords(limit: limit);
  int getTotalPointsByStudent(String id) =>
      _service.getTotalPointsByStudent(id);
  List<SummonsRecord> getSummonsByStudent(String id) =>
      _service.getSummonsByStudent(id);

  Future<void> addRecord(ViolationRecord record) async {
    await _service.addRecord(record);
    notifyListeners();
  }

  Future<void> addSummons(SummonsRecord summons) async {
    await _service.addSummons(summons);
    notifyListeners();
  }
}
