import 'dart:async';

import 'package:flutter/material.dart';

import '../models/counseling_model.dart';
import '../services/counseling_service.dart';

class CounselingProvider extends ChangeNotifier {
  final CounselingService _service = CounselingService();
  List<Appointment> _appointments = [];
  StreamSubscription? _appointmentSub;
  bool _disposed = false;

  List<Appointment> get appointments => _appointments;
  List<Appointment> get upcomingAppointments =>
      _appointments.where((a) => a.status == 'upcoming').toList();

  Future<void> init() async {
    if (_disposed) return;
    await _appointmentSub?.cancel();
    if (_disposed) return;
    _appointmentSub = _service.streamAppointments().listen(
      (apps) {
        if (_disposed) return;
        _appointments = apps;
        notifyListeners();
      },
      onError: (_) {
        if (_disposed) return;
        _appointments = [];
        notifyListeners();
      },
    );
  }

  CounselingService get service => _service;

  @override
  void dispose() {
    _disposed = true;
    _appointmentSub?.cancel();
    _appointmentSub = null;
    super.dispose();
  }
}
