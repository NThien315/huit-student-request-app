// lib/services/auth_service.dart
// TV2 — Code API / Thiết lập Firebase Auth (Task 3.2)
// Handles: Đăng nhập, Đăng xuất, Đổi mật khẩu, Tạo tài khoản (Admin)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Stream trạng thái xác thực ─────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ──────────────────────────────────────────────────────────────────────────
  // UC001 — Đăng nhập
  // ──────────────────────────────────────────────────────────────────────────
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Đăng nhập thất bại');

      // Lấy thông tin chi tiết từ Firestore
      final userModel = await _getUserFromFirestore(user.uid);
      if (userModel == null) throw Exception('Không tìm thấy thông tin tài khoản');

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UC008 — Đăng xuất
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UC002 — Thay đổi mật khẩu
  // Yêu cầu re-authenticate trước để bảo mật
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Chưa đăng nhập');
    }
    if (newPassword.length < 6) {
      throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự');
    }

    try {
      // Bước 1: Re-authenticate với mật khẩu hiện tại
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Bước 2: Cập nhật mật khẩu mới
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tạo tài khoản mới — Chỉ Admin được dùng (gọi từ Admin screen)
  // ──────────────────────────────────────────────────────────────────────────
  Future<UserModel> createAccount({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? studentId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final newUser = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        displayName: displayName,
        role: role,
        studentId: studentId,
        createdAt: DateTime.now(),
      );

      // Lưu thông tin user vào Firestore
      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Lấy UserModel từ Firestore theo UID
  // ──────────────────────────────────────────────────────────────────────────
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // Phiên bản public — dùng cho Provider khi app khởi động
  Future<UserModel?> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _getUserFromFirestore(user.uid);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Cập nhật FCM Token — gọi sau khi NotificationService lấy được token
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Map Firebase error code → thông báo lỗi tiếng Việt
  // ──────────────────────────────────────────────────────────────────────────
  String _mapAuthError(String code) {
    const errors = {
      'user-not-found': 'Tài khoản không tồn tại trong hệ thống',
      'wrong-password': 'Mật khẩu không chính xác',
      'invalid-credential': 'Email hoặc mật khẩu không đúng',
      'email-already-in-use': 'Email này đã được đăng ký',
      'weak-password': 'Mật khẩu quá yếu (tối thiểu 6 ký tự)',
      'invalid-email': 'Địa chỉ email không hợp lệ',
      'too-many-requests': 'Quá nhiều lần thử. Vui lòng thử lại sau',
      'requires-recent-login': 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại',
    };
    return errors[code] ?? 'Lỗi xác thực ($code). Vui lòng thử lại';
  }
}
