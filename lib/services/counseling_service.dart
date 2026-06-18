import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import '../models/counseling_model.dart';
import '../models/counseling_request_model.dart';
import '../models/report_model.dart';
import 'firebase_service.dart';

class CounselingService {

  Map<String, dynamic>? _safeQueryData(QueryDocumentSnapshot doc) {
    final raw = doc.data();
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  Stream<DocumentSnapshot> streamUser(String uid) {
    return FirebaseService.userDoc(uid).snapshots();
  }

  Stream<List<Counselor>> streamCounselors() {
    return FirebaseService.users
        .where('role', isEqualTo: 'admin')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = _safeQueryData(doc);
              if (data == null) return null;
              try {
                return Counselor.fromMap(data, doc.id);
              } catch (_) {
                return null;
              }
            })
            .whereType<Counselor>()
            .toList());
  }

  Stream<List<Appointment>> streamAppointments() {
    return FirebaseService.appointments
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = _safeQueryData(doc);
              if (data == null) return null;
              try {
                return Appointment(
                  id: doc.id,
                  title: (data['title'] as String?) ?? '',
                  description: (data['description'] as String?) ?? '',
                  counselorName: (data['counselorName'] as String?) ?? '',
                  counselorImage: (data['counselorImage'] as String?) ?? '',
                  date: data['date'] != null
                      ? (data['date'] as Timestamp).toDate()
                      : DateTime.now(),
                  time: (data['time'] as String?) ?? '',
                  room: (data['room'] as String?) ?? '',
                  status: (data['status'] as String?) ?? 'upcoming',
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<Appointment>()
            .toList());
  }

  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return FirebaseService.messages(chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = _safeQueryData(doc);
              if (data == null) return null;
              try {
                return ChatMessage(
                  id: doc.id,
                  senderId: (data['senderId'] as String?) ?? '',
                  receiverId: (data['receiverId'] as String?) ?? '',
                  senderName: (data['senderName'] as String?) ?? '',
                  text: (data['text'] as String?) ?? '',
                  createdAt: data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.now(),
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<ChatMessage>()
            .toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String senderName,
    required String receiverName,
    required String senderRole,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    await FirebaseService.chats.doc(chatId).set({
      'participants': [senderId, receiverId],
      'participantInfo': {
        senderId: {'name': senderName},
        receiverId: {'name': receiverName},
      },
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': {
        'senderId': senderId,
        'senderName': senderName,
        'text': text.trim(),
      },
    }, SetOptions(merge: true));

    await FirebaseService.messages(chatId).add({
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitReport(Report report) async {
    try {
      await FirebaseService.reports.add(report.toJson());
    } catch (_) {}
  }

  Future<void> addAppointment(Appointment appointment) async {
    try {
      await FirebaseService.appointments.add(appointment.toJson());
    } catch (_) {}
  }

  Future<void> createCounselingRequest({
    required String studentId,
    required String studentName,
    required String studentClass,
    required String topic,
    required String message,
    String priority = 'rendah',
  }) async {
    final now = FieldValue.serverTimestamp();
    final ref = await FirebaseService.counselingRequests.add({
      'studentId': studentId,
      'studentName': studentName,
      'studentClass': studentClass,
      'topic': topic,
      'message': message,
      'status': 'pending',
      'priority': priority,
      'chatId': null,
      'createdAt': now,
      'updatedAt': now,
    });

    final priorityLabel = switch (priority) {
      'tinggi' => 'tinggi',
      'sedang' => 'sedang',
      _ => 'rendah',
    };

    await FirebaseService.notifications.add({
      'type': 'counseling_request',
      'studentId': studentId,
      'studentName': studentName,
      'priority': priority,
      'requestId': ref.id,
      'title': 'Permintaan Konseling Baru',
      'message': '$studentName mengajukan konseling prioritas $priorityLabel',
      'isRead': false,
      'createdAt': now,
    });
  }

  Stream<List<CounselingRequest>> streamAllRequests() {
    return FirebaseService.counselingRequests
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return CounselingRequest.fromSnapshot(doc);
        } catch (e) {
          return null;
        }
      }).whereType<CounselingRequest>().toList();
    });
  }

  Stream<List<CounselingRequest>> streamStudentRequests(String studentId) {
    debugPrint('[streamStudentRequests] studentId=$studentId');
    debugPrint('[streamStudentRequests] query: counseling_requests.where(studentId == $studentId).snapshots()');

    return FirebaseService.counselingRequests
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .handleError((error, stackTrace) {
          debugPrint('[streamStudentRequests] ERROR: $error');
          debugPrint('[streamStudentRequests] stackTrace: $stackTrace');
        })
        .map((snapshot) {
      final docCount = snapshot.docs.length;
      debugPrint('[streamStudentRequests] snapshot received, docs=$docCount');

      if (docCount > 0) {
        final first = snapshot.docs.first.data() as Map<String, dynamic>;
        debugPrint('[streamStudentRequests] first doc keys: ${first.keys}');
        debugPrint('[streamStudentRequests] first doc has studentId=${first.containsKey('studentId')} (${first['studentId']})');
        debugPrint('[streamStudentRequests] first doc has createdAt=${first.containsKey('createdAt')} (${first['createdAt']?.runtimeType})');
        debugPrint('[streamStudentRequests] first doc has status=${first.containsKey('status')} (${first['status']})');
      }

      final list = snapshot.docs.map((doc) {
        try {
          return CounselingRequest.fromSnapshot(doc);
        } catch (e) {
          debugPrint('[streamStudentRequests] fromSnapshot error for doc ${doc.id}: $e');
          return null;
        }
      }).whereType<CounselingRequest>().toList();

      debugPrint('[streamStudentRequests] parsed ${list.length}/$docCount docs successfully');

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<int> streamPendingCount() {
    return FirebaseService.counselingRequests
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> acceptRequest(String requestId,
      {required String studentId,
      required String studentName,
      required String adminId,
      required String adminName}) async {
    final ids = [studentId, adminId]..sort();
    final chatId = '${ids[0]}_${ids[1]}';
    await FirebaseService.counselingRequests.doc(requestId).update({
      'status': 'accepted',
      'chatId': chatId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await FirebaseService.chats.doc(chatId).set({
      'participants': [studentId, adminId],
      'participantInfo': {
        studentId: {'name': studentName},
        adminId: {'name': adminName},
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, int>> streamPriorityCounts() {
    return FirebaseService.counselingRequests
        .snapshots()
        .map((snapshot) {
      int rendah = 0;
      int sedang = 0;
      int tinggi = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final priority = (data['priority'] as String?) ?? 'rendah';
        switch (priority) {
          case 'tinggi':
            tinggi++;
          case 'sedang':
            sedang++;
          default:
            rendah++;
        }
      }
      return {
        'rendah': rendah,
        'sedang': sedang,
        'tinggi': tinggi,
      };
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await FirebaseService.counselingRequests.doc(requestId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
