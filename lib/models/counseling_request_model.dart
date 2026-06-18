import 'package:cloud_firestore/cloud_firestore.dart';

class CounselingRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String studentClass;
  final String topic;
  final String message;
  final String status;
  final String priority;
  final String? chatId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CounselingRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentClass,
    required this.topic,
    required this.message,
    this.status = 'pending',
    this.priority = 'rendah',
    this.chatId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  static const List<String> priorityValues = ['rendah', 'sedang', 'tinggi'];

  static DateTime _safeTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  factory CounselingRequest.fromSnapshot(
      DocumentSnapshot snapshot) {
    final raw = snapshot.data();
    final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
    return CounselingRequest(
      id: snapshot.id,
      studentId: (data['studentId'] as String?) ?? '',
      studentName: (data['studentName'] as String?) ?? '',
      studentClass: (data['studentClass'] as String?) ?? '',
      topic: (data['topic'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'pending',
      priority: (data['priority'] as String?) ?? 'rendah',
      chatId: data['chatId'] as String?,
      createdAt: _safeTimestamp(data['createdAt']),
      updatedAt: _safeTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'studentClass': studentClass,
        'topic': topic,
        'message': message,
        'status': status,
        'priority': priority,
        'chatId': chatId,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
