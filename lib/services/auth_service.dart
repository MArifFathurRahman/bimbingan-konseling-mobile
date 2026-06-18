import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  const AuthResult({required this.success, this.message, this.user});
}

class AuthService {
  static const String _prefUid = 'auth_uid';
  static const String _prefRole = 'auth_role';

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isWaliKelas => _currentUser?.isWaliKelas ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  Future<AuthResult> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return const AuthResult(success: false, message: 'Email dan password harus diisi');
    }
    try {
      final credential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final uid = credential.user!.uid;
      var query = await FirebaseService.users.where('authUid', isEqualTo: uid).limit(1).get();
      DocumentSnapshot doc;
      if (query.docs.isNotEmpty) {
        doc = query.docs.first;
      } else {
        doc = await FirebaseService.users.doc(uid).get();
      }
      if (!doc.exists) {
        await fb.FirebaseAuth.instance.signOut();
        return const AuthResult(success: false, message: 'Data pengguna tidak ditemukan');
      }
      final raw = doc.data();
      if (raw == null) {
        await fb.FirebaseAuth.instance.signOut();
        return const AuthResult(success: false, message: 'Data pengguna tidak ditemukan');
      }
      final data = raw as Map<String, dynamic>;
      _currentUser = UserModel(
        id: doc.id,
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        nip: (data['nip'] as String?) ?? '',
        role: UserModel.roleFromString((data['role'] as String?) ?? 'student'),
        imageUrl: data['imageUrl'] as String?,
        className: (data['className'] as String?) ?? (data['class'] as String?),
      );
      await _saveSession();
      return AuthResult(success: true, user: _currentUser);
    } on fb.FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found': msg = 'Akun tidak ditemukan'; break;
        case 'wrong-password': msg = 'Password salah'; break;
        case 'invalid-credential': msg = 'Email atau password salah'; break;
        case 'too-many-requests': msg = 'Terlalu banyak percobaan. Coba lagi nanti'; break;
        default: msg = 'Login gagal: ${e.message}'; break;
      }
      return AuthResult(success: false, message: msg);
    } catch (e) {
      return AuthResult(success: false, message: 'Terjadi kesalahan: $e');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await fb.FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUid);
    await prefs.remove(_prefRole);
  }

  Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString(_prefUid);
    final currentUser = fb.FirebaseAuth.instance.currentUser;
    if (currentUser == null || savedUid == null) return false;
    try {
      var query = await FirebaseService.users.where('authUid', isEqualTo: currentUser.uid).limit(1).get();
      DocumentSnapshot doc;
      if (query.docs.isNotEmpty) {
        doc = query.docs.first;
      } else {
        doc = await FirebaseService.users.doc(currentUser.uid).get();
      }
      if (!doc.exists) return false;
      final raw = doc.data();
      if (raw == null) return false;
      final data = raw as Map<String, dynamic>;
      _currentUser = UserModel(
        id: doc.id,
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        nip: (data['nip'] as String?) ?? '',
        role: UserModel.roleFromString((data['role'] as String?) ?? 'student'),
        imageUrl: data['imageUrl'] as String?,
        className: (data['className'] as String?) ?? (data['class'] as String?),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveSession() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefUid, _currentUser!.id);
    await prefs.setString(_prefRole, _currentUser!.role.name);
  }
}
