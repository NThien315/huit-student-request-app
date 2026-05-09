// lib/services/firestore_service.dart
// TV2 — Code API / Thiết lập Firestore (Task 3.2)
// Handles: CRUD yêu cầu, danh mục, quản lý người dùng

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ════════════════════════════════════════════════════════════════════════════
  // DANH MỤC YÊU CẦU (requestCategories)
  // Dùng cho: Admin CRUD, Sinh viên chọn loại yêu cầu
  // ════════════════════════════════════════════════════════════════════════════

  // Lấy danh mục đang hoạt động — hiển thị cho Sinh viên khi tạo yêu cầu
  Stream<List<CategoryModel>> getActiveCategories() {
    return _db
        .collection('requestCategories')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Lấy tất cả danh mục — dành cho Admin quản lý
  Stream<List<CategoryModel>> getAllCategories() {
    return _db
        .collection('requestCategories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // UC006 — Thêm danh mục mới (Admin)
  Future<void> addCategory({
    required String name,
    required String description,
  }) async {
    // Kiểm tra tên không được trùng
    final existing = await _db
        .collection('requestCategories')
        .where('name', isEqualTo: name.trim())
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Tên danh mục "$name" đã tồn tại');
    }

    final category = CategoryModel(
      id: '',
      name: name.trim(),
      description: description.trim(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _db.collection('requestCategories').add(category.toMap());
  }

  // UC006 — Sửa danh mục (Admin)
  Future<void> updateCategory(String id, {String? name, String? description}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (description != null) updates['description'] = description.trim();

    if (updates.isEmpty) return;
    await _db.collection('requestCategories').doc(id).update(updates);
  }

  // UC006 — Bật/Tắt danh mục (Admin) — không xóa cứng
  Future<void> toggleCategoryActive(String id, {required bool isActive}) async {
    await _db
        .collection('requestCategories')
        .doc(id)
        .update({'isActive': isActive});
  }

  // ════════════════════════════════════════════════════════════════════════════
  // YÊU CẦU (requests)
  // ════════════════════════════════════════════════════════════════════════════

  // UC003 — Sinh viên tạo yêu cầu mới → trạng thái mặc định: pending
  Future<String> createRequest({
    required UserModel student,
    required CategoryModel category,
    required String reason,
    List<String> attachmentUrls = const [],
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Vui lòng nhập lý do yêu cầu');
    }

    final now = DateTime.now();
    final request = RequestModel(
      id: '',
      studentUid: student.uid,
      studentName: student.displayName,
      studentId: student.studentId ?? '',
      categoryId: category.id,
      categoryName: category.name,
      reason: reason.trim(),
      attachmentUrls: attachmentUrls,
      status: RequestStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    final docRef = await _db.collection('requests').add(request.toMap());
    return docRef.id; // Trả về ID để điều hướng đến màn hình chi tiết
  }

  // UC004 — Lấy danh sách yêu cầu của một sinh viên (real-time stream)
  Stream<List<RequestModel>> getStudentRequests(String studentUid) {
    return _db
        .collection('requests')
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RequestModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // UC005 — Lấy tất cả yêu cầu (Giáo vụ/Admin), có thể lọc theo trạng thái
  Stream<List<RequestModel>> getAllRequests({RequestStatus? filterStatus}) {
    Query<Map<String, dynamic>> query = _db
        .collection('requests')
        .orderBy('createdAt', descending: true);

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus.name);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((doc) => RequestModel.fromMap(doc.id, doc.data()))
        .toList());
  }

  // UC005 — Lấy yêu cầu "Chờ tiếp nhận" (Giáo vụ xử lý trước)
  Stream<List<RequestModel>> getPendingRequests() {
    return _db
        .collection('requests')
        .where('status', isEqualTo: RequestStatus.pending.name)
        .orderBy('createdAt') // FIFO — ai gửi trước xử lý trước
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RequestModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Lấy chi tiết một yêu cầu theo ID
  Future<RequestModel?> getRequestById(String requestId) async {
    final doc = await _db.collection('requests').doc(requestId).get();
    if (!doc.exists || doc.data() == null) return null;
    return RequestModel.fromMap(doc.id, doc.data()!);
  }

  // UC005 — Giáo vụ cập nhật trạng thái + ghi chú phản hồi
  // Firestore trigger sẽ tự gửi FCM notification sau khi update thành công
  Future<void> updateRequestStatus({
    required String requestId,
    required RequestStatus newStatus,
    required String staffUid,
    String? note,
  }) async {
    if (newStatus == RequestStatus.rejected && (note == null || note.trim().isEmpty)) {
      throw Exception('Vui lòng nhập lý do từ chối để thông báo cho sinh viên');
    }

    await _db.collection('requests').doc(requestId).update({
      'status': newStatus.name,
      'note': note?.trim(),
      'staffUid': staffUid,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // NGƯỜI DÙNG (users)
  // ════════════════════════════════════════════════════════════════════════════

  // Lấy thông tin một user theo UID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  // Lấy danh sách tất cả user (Admin)
  Stream<List<UserModel>> getAllUsers() {
    return _db
        .collection('users')
        .orderBy('displayName')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // Lấy danh sách user theo role
  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role.name)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SEED DATA — Tạo dữ liệu mẫu ban đầu (chỉ chạy 1 lần khi deploy)
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> seedCategories() async {
    final existing = await _db.collection('requestCategories').limit(1).get();
    if (existing.docs.isNotEmpty) return; // Đã có data, không seed lại

    final categories = [
      {'name': 'Xin bảng điểm', 'description': 'Cấp bảng điểm toàn khoá hoặc từng học kỳ'},
      {'name': 'Xác nhận sinh viên', 'description': 'Giấy xác nhận đang là sinh viên của trường'},
      {'name': 'Phúc khảo bài thi', 'description': 'Yêu cầu chấm phúc khảo bài thi cuối kỳ'},
      {'name': 'Đăng ký môn học', 'description': 'Đăng ký/rút môn ngoài thời gian quy định'},
      {'name': 'Xin miễn giảm học phí', 'description': 'Yêu cầu xem xét miễn/giảm học phí'},
      {'name': 'Giấy xác nhận vay vốn', 'description': 'Xác nhận để vay vốn ngân hàng chính sách'},
    ];

    final batch = _db.batch();
    for (final cat in categories) {
      final ref = _db.collection('requestCategories').doc();
      batch.set(ref, {
        ...cat,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }
}
