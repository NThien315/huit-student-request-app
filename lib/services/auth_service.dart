import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  // Biến gọi Supabase Client
  final _supabase = Supabase.instance.client;

  // Lấy user hiện tại của Supabase
  User? get currentUser => _supabase.auth.currentUser;

  // Lắng nghe trạng thái đăng nhập/đăng xuất
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // --- ĐĂNG NHẬP ---
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Sau khi đăng nhập thành công, rút thông tin chi tiết từ bảng 'users'
        final userData = await _supabase
            .from('users')
            .select()
            .eq('uid', response.user!.id)
            .single();
            
        return UserModel.fromMap(userData);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  // --- ĐĂNG XUẤT ---
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ─── CẤP TÀI KHOẢN GIÁO VỤ ───
  Future<void> createStaffAccount({
    required String email,
    required String password,
    required String fullName,
    required String staffId,
    required String role, // 'staff' hoặc 'admin'
  }) async {
    try {
      // 1. Tạo user trong hệ thống Supabase Auth (Đăng ký tài khoản ngầm)
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final String? newUid = response.user?.id;

      if (newUid != null) {
        // 2. Chèn thông tin chi tiết của Giáo vụ vào bảng 'users' trong Database
        await _supabase.from('users').insert({
          'uid': newUid,
          'email': email,
          'name': fullName,
          'studentId': staffId,
          'role': role,
        });
      }
    } catch (e) {
      throw Exception('Lỗi cấp tài khoản giáo vụ: $e');
    }
  }
}