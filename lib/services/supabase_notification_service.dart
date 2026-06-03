// lib/services/supabase_notification_service.dart
// TV2 — Ghi thông báo vào Supabase để trigger Edge Function gửi FCM
// UC007 — Sinh viên nhận Push Notification khi trạng thái yêu cầu thay đổi
//
// Luồng hoạt động:
// ┌─────────────────────┐     ┌───────────────────────┐     ┌──────────────┐
// │ Giáo vụ cập nhật    │ ──► │ Ghi record vào bảng   │ ──► │ Webhook      │
// │ trạng thái yêu cầu  │     │ 'notifications'       │     │ trigger FCM  │
// └─────────────────────┘     └───────────────────────┘     └──────────────┘

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseNotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  // ════════════════════════════════════════════════════════════════════════════
  // GHI THÔNG BÁO VÀO SUPABASE
  // Khi record được INSERT → Supabase Database Webhook tự gọi Edge Function
  // Edge Function đọc FCM token và gửi push notification qua Firebase
  // ════════════════════════════════════════════════════════════════════════════

  /// Tạo thông báo cập nhật trạng thái yêu cầu
  /// Được gọi sau khi Giáo vụ/Admin cập nhật trạng thái thành công trên Firestore
  ///
  /// [studentUid] — UID của sinh viên cần nhận thông báo
  /// [title] — Tiêu đề thông báo (VD: "Yêu cầu đã được duyệt")
  /// [body] — Nội dung chi tiết (VD: "Yêu cầu Xin bảng điểm đã được hoàn thành")
  /// [requestId] — ID yêu cầu trên Firestore (để điều hướng khi tap)
  Future<void> createNotification({
    required String studentUid,
    required String title,
    required String body,
    required String requestId,
  }) async {
    try {
      await _client.from('notifications').insert({
        'student_uid': studentUid,
        'title': title,
        'body': body,
        'request_id': requestId,
        'is_sent': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      print('[Notification] ✅ Đã ghi thông báo cho SV: $studentUid');
    } catch (e) {
      // Không throw — notification là tính năng phụ, không nên block flow chính
      print('[Notification] ⚠️ Lỗi ghi thông báo: $e');
    }
  }

  /// Tạo thông báo khi yêu cầu được tiếp nhận (processing)
  Future<void> notifyRequestProcessing({
    required String studentUid,
    required String requestId,
    required String categoryName,
  }) async {
    await createNotification(
      studentUid: studentUid,
      title: 'Yêu cầu đang được xử lý',
      body: 'Yêu cầu "$categoryName" của bạn đã được tiếp nhận và đang xử lý.',
      requestId: requestId,
    );
  }

  /// Tạo thông báo khi yêu cầu hoàn thành (completed)
  Future<void> notifyRequestCompleted({
    required String studentUid,
    required String requestId,
    required String categoryName,
  }) async {
    await createNotification(
      studentUid: studentUid,
      title: 'Yêu cầu đã hoàn thành ✅',
      body: 'Yêu cầu "$categoryName" của bạn đã được xử lý xong. Vui lòng kiểm tra kết quả.',
      requestId: requestId,
    );
  }

  /// Tạo thông báo khi yêu cầu bị từ chối (rejected)
  Future<void> notifyRequestRejected({
    required String studentUid,
    required String requestId,
    required String categoryName,
    String? reason,
  }) async {
    final reasonText = reason != null ? '\nLý do: $reason' : '';
    await createNotification(
      studentUid: studentUid,
      title: 'Yêu cầu bị từ chối',
      body: 'Yêu cầu "$categoryName" của bạn đã bị từ chối.$reasonText',
      requestId: requestId,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LẤY LỊCH SỬ THÔNG BÁO (tuỳ chọn — dùng nếu cần hiển thị danh sách)
  // ════════════════════════════════════════════════════════════════════════════

  /// Lấy danh sách thông báo của một sinh viên
  Future<List<Map<String, dynamic>>> getNotifications(String studentUid) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('student_uid', studentUid)
          .order('created_at', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[Notification] ⚠️ Lỗi lấy lịch sử thông báo: $e');
      return [];
    }
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('[Notification] ⚠️ Lỗi đánh dấu đã đọc: $e');
    }
  }
}
