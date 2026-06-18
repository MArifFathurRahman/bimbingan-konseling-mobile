import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String type;
  final String studentId;
  final String studentName;
  final String priority;
  final String requestId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.studentId,
    required this.studentName,
    required this.priority,
    required this.requestId,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  static DateTime _safeTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  factory NotificationItem.fromSnapshot(DocumentSnapshot snapshot) {
    final raw = snapshot.data();
    final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
    return NotificationItem(
      id: snapshot.id,
      type: (data['type'] as String?) ?? '',
      studentId: (data['studentId'] as String?) ?? '',
      studentName: (data['studentName'] as String?) ?? '',
      priority: (data['priority'] as String?) ?? 'rendah',
      requestId: (data['requestId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      message: (data['message'] as String?) ?? '',
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: _safeTimestamp(data['createdAt']),
    );
  }
}
