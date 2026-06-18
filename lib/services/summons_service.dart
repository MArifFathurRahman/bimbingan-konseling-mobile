import '../models/student_model.dart';

class SummonsRequest {
  final Student student;
  final String reason;
  final DateTime date;
  final String time;
  final String location;

  SummonsRequest({
    required this.student,
    required this.reason,
    required this.date,
    required this.time,
    this.location = 'Ruang Bimbingan Konseling',
  });
}

class SummonsService {
  final List<SummonsRequest> _history = [];

  List<SummonsRequest> getHistory() => _history;

  void generateSummons(SummonsRequest request) {
    _history.add(request);
  }
}
