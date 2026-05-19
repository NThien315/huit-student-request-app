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
}