class ViolationCategory {
  final String id;
  final String name;
  final List<ViolationItem> items;

  const ViolationCategory({
    required this.id,
    required this.name,
    required this.items,
  });
}

class ViolationItem {
  final String id;
  final String description;
  final int points;

  const ViolationItem({
    required this.id,
    required this.description,
    required this.points,
  });
}

class ViolationRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String categoryId;
  final String categoryName;
  final String violationId;
  final String violationDescription;
  final int points;
  final DateTime date;
  final String? note;
  final String recordedBy;

  ViolationRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.categoryId,
    required this.categoryName,
    required this.violationId,
    required this.violationDescription,
    required this.points,
    required this.date,
    this.note,
    required this.recordedBy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'violationId': violationId,
    'violationDescription': violationDescription,
    'points': points,
    'date': date.toIso8601String(),
    'note': note,
    'recordedBy': recordedBy,
  };
}

class SafetyScoreEntry {
  final DateTime date;
  final int score;
  final String label;

  SafetyScoreEntry({
    required this.date,
    required this.score,
    required this.label,
  });
}

class SummonsRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String reason;
  final DateTime date;
  final String time;
  final String location;
  final DateTime createdAt;
  final String status;

  SummonsRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.reason,
    required this.date,
    required this.time,
    this.location = 'Ruang Bimbingan Konseling',
    DateTime? createdAt,
    this.status = 'sent',
  }) : createdAt = createdAt ?? DateTime.now();
}

class CounselingSession {
  final String id;
  final String counselorName;
  final DateTime date;
  final String time;
  final String status;
  final String? topic;

  CounselingSession({
    required this.id,
    required this.counselorName,
    required this.date,
    required this.time,
    this.status = 'completed',
    this.topic,
  });
}
