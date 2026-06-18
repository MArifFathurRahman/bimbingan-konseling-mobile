import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  UserModel? get user => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isAdmin => _authService.isAdmin;
  bool get isWaliKelas => _authService.isWaliKelas;
  bool get isStudent => _authService.isStudent;

  Future<void> initialize() async {
    await _authService.tryRestoreSession();
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    _isLoading = false;
    if (!result.success) {
      _error = result.message;
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
