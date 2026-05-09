// lib/providers/auth_provider.dart
// TV2 — State Management cho xác thực người dùng (Task 3.2)

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ─────────────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Helpers phân quyền — dùng trong UI để ẩn/hiện widget
  bool get isStudent => _currentUser?.role == UserRole.student;
  bool get isStaff => _currentUser?.role == UserRole.staff;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isStaffOrAdmin =>
      _currentUser?.role == UserRole.staff ||
      _currentUser?.role == UserRole.admin;

  // ── Internal helpers ─────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Kiểm tra session khi app khởi động (Auto-login)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> checkAuthState() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.fetchCurrentUser();
    } catch (_) {
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UC001 — Đăng nhập
  // Trả về true nếu thành công
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UC008 — Đăng xuất
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UC002 — Đổi mật khẩu
  // Trả về true nếu thành công
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      _setError('Mật khẩu xác nhận không trùng khớp');
      return false;
    }

    _setLoading(true);
    _setError(null);
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
