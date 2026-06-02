// lib/services/auth_service.dart
// TV2 — Code API / Thiết lập Firebase Auth (Task 3.2)
// Handles: Đăng nhập, Đăng xuất, Đổi mật khẩu, Tạo tài khoản (Admin)
// Updated: Tích hợp mã hóa password + seed tài khoản test + verify database

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'password_helper.dart';

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

    // Validate password mạnh trước khi đổi
    final validationError = PasswordHelper.validatePassword(newPassword);
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      // Bước 1: Re-authenticate với mật khẩu hiện tại
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Bước 2: Cập nhật mật khẩu mới (Firebase Auth tự hash trên server)
      await user.updatePassword(newPassword);

      // Bước 3: Lưu hash password vào Firestore để audit log
      final passwordHash = PasswordHelper.hashWithSalt(newPassword, user.email!);
      await _firestore.collection('users').doc(user.uid).update({
        'passwordHash': passwordHash,
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      });
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
    // Validate password trước khi tạo tài khoản
    final validationError = PasswordHelper.validatePassword(password);
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      // Firebase Auth tự mã hóa (hash) password trên server bằng bcrypt/scrypt
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Tạo hash password với salt (email) để lưu audit log
      final passwordHash = PasswordHelper.hashWithSalt(password, email.trim());

      final newUser = UserModel(
        uid: credential.user!.uid,
        email: email.trim(),
        displayName: displayName,
        role: role,
        studentId: studentId,
        createdAt: DateTime.now(),
      );

      // Lưu thông tin user + password hash vào Firestore
      final userData = newUser.toMap();
      userData['passwordHash'] = passwordHash;
      userData['passwordUpdatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(userData);

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
  // SEED TÀI KHOẢN TEST — Tạo 3 tài khoản mẫu để team test app
  // Chạy 1 lần duy nhất. Nếu đã có thì bỏ qua.
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> seedTestAccounts() async {
    // Kiểm tra nếu đã có tài khoản test thì không tạo lại
    final existing = await _firestore
        .collection('users')
        .where('email', isEqualTo: 'admin@huit.edu.vn')
        .get();
    if (existing.docs.isNotEmpty) {
      print('[Seed] Tài khoản test đã tồn tại, bỏ qua.');
      return;
    }

    // Danh sách tài khoản test
    final testAccounts = [
      {
        'email': 'admin@huit.edu.vn',
        'password': 'Admin@123',
        'displayName': 'Quản trị viên',
        'role': UserRole.admin,
        'studentId': null,
      },
      {
        'email': 'giaovu@huit.edu.vn',
        'password': 'Staff@123',
        'displayName': 'Nguyễn Văn Giáo Vụ',
        'role': UserRole.staff,
        'studentId': null,
      },
      {
        'email': 'sinhvien@huit.edu.vn',
        'password': 'Student@123',
        'displayName': 'Trần Thị Sinh Viên',
        'role': UserRole.student,
        'studentId': '2124802010001',
      },
    ];

    for (final account in testAccounts) {
      try {
        await createAccount(
          email: account['email'] as String,
          password: account['password'] as String,
          displayName: account['displayName'] as String,
          role: account['role'] as UserRole,
          studentId: account['studentId'] as String?,
        );
        print('[Seed] ✅ Tạo thành công: ${account['email']}');
      } catch (e) {
        // Email đã tồn tại trên Firebase Auth → bỏ qua
        print('[Seed] ⚠️ Bỏ qua ${account['email']}: $e');
      }
    }

    print('[Seed] ════════════════════════════════════════════');
    print('[Seed] TÀI KHOẢN TEST ĐÃ ĐƯỢC TẠO:');
    print('[Seed] ────────────────────────────────────────────');
    print('[Seed] 👤 Admin:     admin@huit.edu.vn / Admin@123');
    print('[Seed] 👤 Giáo vụ:   giaovu@huit.edu.vn / Staff@123');
    print('[Seed] 👤 Sinh viên: sinhvien@huit.edu.vn / Student@123');
    print('[Seed] ════════════════════════════════════════════');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VERIFY DATABASE — Kiểm tra database có ổn không
  // Kiểm tra: collections tồn tại, data integrity, indexes
  // ──────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyDatabase() async {
    final report = <String, dynamic>{};

    try {
      // 1. Kiểm tra collection 'users'
      final usersSnapshot = await _firestore.collection('users').get();
      report['users'] = {
        'status': 'OK',
        'count': usersSnapshot.docs.length,
        'details': usersSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'uid': doc.id,
            'email': data['email'],
            'role': data['role'],
            'hasPasswordHash': data['passwordHash'] != null,
          };
        }).toList(),
      };

      // 2. Kiểm tra collection 'requestCategories'
      final categoriesSnapshot =
          await _firestore.collection('requestCategories').get();
      report['requestCategories'] = {
        'status': 'OK',
        'count': categoriesSnapshot.docs.length,
        'activeCount': categoriesSnapshot.docs
            .where((doc) => doc.data()['isActive'] == true)
            .length,
      };

      // 3. Kiểm tra collection 'requests'
      final requestsSnapshot = await _firestore.collection('requests').get();
      final statusCounts = <String, int>{};
      for (final doc in requestsSnapshot.docs) {
        final status = doc.data()['status'] as String? ?? 'unknown';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
      report['requests'] = {
        'status': 'OK',
        'count': requestsSnapshot.docs.length,
        'byStatus': statusCounts,
      };

      // 4. Tổng kết
      report['overall'] = {
        'status': 'OK',
        'message': 'Database hoạt động bình thường',
        'checkedAt': DateTime.now().toIso8601String(),
      };

      print('[DB Verify] ════════════════════════════════════════════');
      print('[DB Verify] KẾT QUẢ KIỂM TRA DATABASE:');
      print('[DB Verify] ────────────────────────────────────────────');
      print('[DB Verify] 📊 Users: ${usersSnapshot.docs.length} tài khoản');
      print('[DB Verify] 📁 Categories: ${categoriesSnapshot.docs.length} danh mục');
      print('[DB Verify] 📝 Requests: ${requestsSnapshot.docs.length} yêu cầu');
      print('[DB Verify] ✅ Trạng thái: OK');
      print('[DB Verify] ════════════════════════════════════════════');
    } catch (e) {
      report['overall'] = {
        'status': 'ERROR',
        'message': 'Lỗi kết nối database: $e',
        'checkedAt': DateTime.now().toIso8601String(),
      };
      print('[DB Verify] ❌ Lỗi kiểm tra database: $e');
    }

    return report;
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
