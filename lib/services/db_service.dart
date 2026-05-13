// lib/services/db_service.dart
// TV2 — Lớp trừu tượng Kéo/Đẩy dữ liệu lên Firestore (Task 3.2)
// File này wrap FirestoreService + AuthService, cung cấp API đơn giản
// cho TV1 (UI) và TV3 (State) sử dụng mà không cần biết chi tiết Firestore.

import '../models/user_model.dart';
import '../models/request_model.dart';
import '../models/category_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

/// DbService — Lớp trung gian (Facade pattern) quản lý toàn bộ thao tác
/// đọc/ghi dữ liệu giữa Flutter app và Firebase.
///
/// TV1 và TV3 chỉ cần khởi tạo `DbService()` và gọi các method bên dưới,
/// không cần import trực tiếp FirestoreService hay AuthService.
///
/// ```dart
/// final db = DbService();
///
/// // Đăng nhập
/// final user = await db.signIn('email@huit.edu.vn', 'password');
///
/// // Tạo yêu cầu
/// await db.createRequest(student: user, category: cat, reason: 'Lý do');
///
/// // Lấy danh sách yêu cầu (real-time)
/// db.getStudentRequests(user.uid).listen((list) => print(list));
/// ```
class DbService {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // ════════════════════════════════════════════════════════════════════════════
  // XÁC THỰC (Authentication)
  // ════════════════════════════════════════════════════════════════════════════

  /// UC001 — Đăng nhập bằng Email/Password
  /// Trả về [UserModel] chứa thông tin tài khoản nếu thành công.
  /// Throw Exception nếu sai email/mật khẩu.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) {
    return _authService.signIn(email: email, password: password);
  }

  /// UC008 — Đăng xuất khỏi hệ thống
  Future<void> signOut() {
    return _authService.signOut();
  }

  /// UC002 — Đổi mật khẩu
  /// Yêu cầu nhập mật khẩu hiện tại để xác minh danh tính trước.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Tạo tài khoản mới — Chỉ Admin sử dụng
  Future<UserModel> createAccount({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
    String? studentId,
  }) {
    return _authService.createAccount(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
      studentId: studentId,
    );
  }

  /// Lấy thông tin user đang đăng nhập
  Future<UserModel?> fetchCurrentUser() {
    return _authService.fetchCurrentUser();
  }

  /// Stream theo dõi trạng thái đăng nhập (đăng nhập / đăng xuất)
  Stream get authStateChanges => _authService.authStateChanges;

  // ════════════════════════════════════════════════════════════════════════════
  // DANH MỤC YÊU CẦU (Request Categories)
  // ════════════════════════════════════════════════════════════════════════════

  /// Lấy danh mục đang hoạt động — dùng cho Sinh viên chọn loại yêu cầu
  Stream<List<CategoryModel>> getActiveCategories() {
    return _firestoreService.getActiveCategories();
  }

  /// Lấy tất cả danh mục (kể cả đã ẩn) — dùng cho Admin quản lý
  Stream<List<CategoryModel>> getAllCategories() {
    return _firestoreService.getAllCategories();
  }

  /// UC006 — Thêm danh mục mới (Admin)
  Future<void> addCategory({
    required String name,
    required String description,
  }) {
    return _firestoreService.addCategory(name: name, description: description);
  }

  /// UC006 — Sửa danh mục (Admin)
  Future<void> updateCategory(String id,
      {String? name, String? description}) {
    return _firestoreService.updateCategory(id,
        name: name, description: description);
  }

  /// UC006 — Bật / Tắt danh mục (Admin) — không xóa cứng
  Future<void> toggleCategoryActive(String id, {required bool isActive}) {
    return _firestoreService.toggleCategoryActive(id, isActive: isActive);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // YÊU CẦU CỦA SINH VIÊN (Requests)
  // ════════════════════════════════════════════════════════════════════════════

  /// UC003 — Sinh viên tạo yêu cầu mới
  /// Trả về requestId để điều hướng đến trang chi tiết.
  Future<String> createRequest({
    required UserModel student,
    required CategoryModel category,
    required String reason,
    List<String> attachmentUrls = const [],
  }) {
    return _firestoreService.createRequest(
      student: student,
      category: category,
      reason: reason,
      attachmentUrls: attachmentUrls,
    );
  }

  /// UC004 — Lấy danh sách yêu cầu của một sinh viên (real-time)
  Stream<List<RequestModel>> getStudentRequests(String studentUid) {
    return _firestoreService.getStudentRequests(studentUid);
  }

  /// UC005 — Lấy tất cả yêu cầu (Giáo vụ / Admin), có thể lọc theo trạng thái
  Stream<List<RequestModel>> getAllRequests({RequestStatus? filterStatus}) {
    return _firestoreService.getAllRequests(filterStatus: filterStatus);
  }

  /// Lấy yêu cầu đang chờ tiếp nhận (FIFO)
  Stream<List<RequestModel>> getPendingRequests() {
    return _firestoreService.getPendingRequests();
  }

  /// Lấy chi tiết một yêu cầu theo ID
  Future<RequestModel?> getRequestById(String requestId) {
    return _firestoreService.getRequestById(requestId);
  }

  /// UC005 — Giáo vụ cập nhật trạng thái + ghi chú phản hồi
  Future<void> updateRequestStatus({
    required String requestId,
    required RequestStatus newStatus,
    required String staffUid,
    String? note,
  }) {
    return _firestoreService.updateRequestStatus(
      requestId: requestId,
      newStatus: newStatus,
      staffUid: staffUid,
      note: note,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // NGƯỜI DÙNG (Users)
  // ════════════════════════════════════════════════════════════════════════════

  /// Lấy thông tin một user theo UID
  Future<UserModel?> getUserById(String uid) {
    return _firestoreService.getUserById(uid);
  }

  /// Lấy danh sách tất cả user (Admin)
  Stream<List<UserModel>> getAllUsers() {
    return _firestoreService.getAllUsers();
  }

  /// Lấy danh sách user theo role
  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _firestoreService.getUsersByRole(role);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // THỐNG KÊ (Dashboard — Admin/Giáo vụ)
  // ════════════════════════════════════════════════════════════════════════════

  /// Lấy số lượng yêu cầu theo từng trạng thái — dùng hiển thị dashboard
  Future<Map<RequestStatus, int>> getRequestStats() {
    return _firestoreService.getRequestStats();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SEED DATA
  // ════════════════════════════════════════════════════════════════════════════

  /// Tạo dữ liệu danh mục mẫu ban đầu (chạy 1 lần khi deploy)
  Future<void> seedCategories() {
    return _firestoreService.seedCategories();
  }
}
