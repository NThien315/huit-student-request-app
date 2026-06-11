import 'dart:io';
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/models/notification_model.dart'; // Giữ nguyên import này
import 'package:huit_student_request_app/services/auth_service.dart'; // Thêm import AuthService
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';

class DbService {
  final _supabase = Supabase.instance.client;

  // ─── 1. THAO TÁC VỚI STORAGE (FILE) ──────────────────────────────────────────
  Future<String?> uploadFileToStorage(String filePath, String uid) async {
    try {
      final file = File(filePath);
      final fileName = filePath.split('/').last;
      final path = 'uploads/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage.from('attachments').upload(path, file);

      // Lấy link URL công khai
      return _supabase.storage.from('attachments').getPublicUrl(path);
    } catch (e) {
      debugPrint("Lỗi tải file lên Supabase: $e");
      return null;
    }
  }

  // ─── 2. THAO TÁC VỚI REQUESTS (YÊU CẦU) ────────────────────────────────────
  
  // Tạo đơn yêu cầu mới
  Future<void> createRequest(RequestModel request) async {
    try {
      await _supabase.from('requests').insert(request.toMap());
      await logAudit('CREATE', 'Request', 'Created new request: ${request.id} by ${request.studentName}');
    } catch (e) {
      throw Exception('Lỗi khi tạo yêu cầu: $e');
    }
  }

  // Lấy danh sách yêu cầu của MỘT sinh viên (Dùng Stream để tự động cập nhật UI)
  Stream<List<RequestModel>> getStudentRequestsStream(String studentUid) {
    return _supabase
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('studentUid', studentUid)
        .order('createdAt', ascending: false)
        .map((maps) => maps.map((map) => RequestModel.fromMap(map)).toList());
  }

  // ─── 3. THAO TÁC VỚI CATEGORIES (LOẠI YÊU CẦU) ─────────────────────────────
  
  // Lấy danh sách Loại yêu cầu đang hoạt động
  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final data = await _supabase
          .from('request_categories')
          .select()
          .eq('isActive', true)
          .order('name', ascending: true);
          
      return data.map((map) => CategoryModel.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh mục: $e');
    }
  }

  // Lấy danh sách Loại yêu cầu (Dạng Stream)
  Stream<List<CategoryModel>> getActiveCategoriesStream() {
    return _supabase
        .from('request_categories')
        .stream(primaryKey: ['id'])
        .eq('isActive', true)
        .map((maps) => maps.map((map) => CategoryModel.fromMap(map)).toList());
  }

  // ─── 4. THAO TÁC VỚI USERS (NGƯỜI DÙNG) ────────────────────────────────────
  
  Future<UserModel?> getUserData(String uid) async {
    try {
      final data = await _supabase.from('users').select().eq('uid', uid).single();
      return UserModel.fromMap(data);
    } catch (e) {
      debugPrint("Lỗi lấy thông tin user: $e");
      return null;
    }
  }

  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    try {
      // Dùng Supabase.instance.client để gọi thẳng từ thư viện gốc, 
      // giúp an toàn tuyệt đối và không lo bị lỗi "không hiểu _supabase" nữa.
      await Supabase.instance.client
          .from('requests')
          .update({'status': newStatus})
          .eq('id', requestId);
      await logAudit('UPDATE', 'Request', 'Updated request ${requestId} status to ${newStatus}');
    } catch (e) {
      debugPrint("Lỗi cập nhật trạng thái đơn trên Supabase: $e");
      rethrow; // Đẩy lỗi ra ngoài để trang Chi tiết bắt được và hiện GlassToast
    }
  }

  // ─── LẮNG NGHE THÔNG BÁO REAL-TIME ─────────────────────────────────────
  Stream<List<NotificationModel>> getNotificationsStream(String studentUid) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('studentUid', studentUid)
        .order('createdAt', ascending: false)
        .map((data) => data.map((map) => NotificationModel.fromMap(map)).toList());
  }

  // ─── ĐÁNH DẤU THÔNG BÁO ĐÃ ĐỌC ──────────────────────────────────────────
  Future<void> markNotificationAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'isRead': true})
        .eq('id', notificationId);
  }

  // Đánh dấu đọc tất cả
  Future<void> markAllNotificationsAsRead(String studentUid) async {
    await _supabase
        .from('notifications')
        .update({'isRead': true})
        .eq('studentUid', studentUid)
        .eq('isRead', false);
  }

  // Public method for audit logging
  Future<void> logAudit(String action, String target, String details) async {
    try {
      final user = AuthService().currentUser; // Lấy thông tin người đang thao tác từ AuthService
      UserModel? appUser;
      if (user != null) appUser = await getUserData(user.id); // Lấy UserModel để có thuộc tính 'name'
      await Supabase.instance.client.from('audit_logs').insert({
        'actor_name': appUser?.name ?? 'Ẩn danh', // Sử dụng name từ UserModel
        'actor_email': appUser?.email ?? user?.email ?? 'Không rõ', // Ưu tiên email từ UserModel, nếu không có thì dùng từ Supabase User
        'action_type': action,
        'target_name': target,
        'details': details,
      });
    } catch (e) {
      debugPrint('Lỗi ghi log: $e');
    }
  }
}