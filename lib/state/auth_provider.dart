// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  // Kiểm tra session khi app khởi động
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> initAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Lấy user hiện tại đang lưu trong Session của Supabase
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser != null) {
        // 2. Nạp chi tiết thông tin từ bảng dữ liệu users
        final userData = await Supabase.instance.client
            .from('users')
            .select()
            .eq('uid', currentUser.id)
            .single();

        // 3. Gán vào biến hệ thống -> isAuthenticated tự động thành true
        _currentUser = UserModel.fromMap(userData);

        // 4. Đồng bộ mã thông báo đẩy FCM
        final fcmToken = await NotificationService.getFCMToken();
        if (fcmToken != null) {
          await Supabase.instance.client
              .from('users')
              .update({'fcm_token': fcmToken})
              .eq('uid', currentUser.id);
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      debugPrint("Lỗi tự động đăng nhập: $e");
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UC001 — Đăng nhập (Đã tối ưu logic nối đuôi email)
  // ──────────────────────────────────────────────────────────────────────────
  Future<bool> signIn(String mssv, String password) async {
    _setLoading(true);
    _setError(null);
    
    // Tự động định dạng email chuẩn cho Supabase
    final email = mssv.contains('@') ? mssv : '$mssv@hdpe.edu.vn';

    try {
      final user = await _authService.signIn(email, password);
      
      // Gán user để kích hoạt trạng thái isAuthenticated
      _currentUser = user;
      
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
    
    // Logic đổi mật khẩu sẽ được TV2 cập nhật sau
    _setLoading(false);
    return false; 
  }

}