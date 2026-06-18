import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static CollectionReference get users => firestore.collection('users');
  static CollectionReference get violations => firestore.collection('violations');
  static CollectionReference get reports => firestore.collection('reports');
  static CollectionReference get summons => firestore.collection('summons');
  static CollectionReference get appointments => firestore.collection('appointments');
  static CollectionReference get chats => firestore.collection('chats');
  static CollectionReference get counselingRequests => firestore.collection('counseling_requests');
  static CollectionReference get notifications => firestore.collection('notifications');

  static CollectionReference messages(String chatId) =>
      chats.doc(chatId).collection('messages');

  static DocumentReference userDoc(String uid) => users.doc(uid);
}
