import 'dart:async';

import '../models/notification_model.dart';
import 'firebase_service.dart';

class RealtimeNotificationService {
  static final RealtimeNotificationService _instance =
      RealtimeNotificationService._();
  RealtimeNotificationService._();

  factory RealtimeNotificationService() => _instance;

  final StreamController<NotificationItem> _newNotificationController =
      StreamController<NotificationItem>.broadcast();

  Stream<NotificationItem> get onNewNotification =>
      _newNotificationController.stream;

  StreamSubscription? _subscription;
  Set<String> _knownIds = {};
  bool _initialized = false;

  void startListening() {
    _subscription?.cancel();
    _knownIds = {};
    _initialized = false;

    _subscription = FirebaseService.notifications
        .where('type', isEqualTo: 'counseling_request')
        .snapshots()
        .listen((snapshot) {
      final currentIds = snapshot.docs.map((doc) => doc.id).toSet();

      if (!_initialized) {
        _knownIds = currentIds;
        _initialized = true;
        return;
      }

      final newIds = currentIds.difference(_knownIds);
      for (final id in newIds) {
        final doc = snapshot.docs.firstWhere((d) => d.id == id);
        final item = NotificationItem.fromSnapshot(doc);
        _newNotificationController.add(item);
      }
      _knownIds = currentIds;
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  void dispose() {
    stopListening();
    _newNotificationController.close();
  }
}
