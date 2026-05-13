// lib/models/request_model.dart
// TV2 — Thiết kế cấu trúc dữ liệu yêu cầu sinh viên (Task 2.2)

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enum trạng thái yêu cầu ─────────────────────────────────────────────────
enum RequestStatus { pending, processing, completed, rejected }

extension RequestStatusX on RequestStatus {
  // Nhãn hiển thị tiếng Việt
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Chờ tiếp nhận';
      case RequestStatus.processing:
        return 'Đang xử lý';
      case RequestStatus.completed:
        return 'Đã hoàn thành';
      case RequestStatus.rejected:
        return 'Bị từ chối';
    }
  }

  // Màu badge tương ứng (hex string)
  String get colorHex {
    switch (this) {
      case RequestStatus.pending:
        return '#FFA000'; // Amber
      case RequestStatus.processing:
        return '#1976D2'; // Blue
      case RequestStatus.completed:
        return '#388E3C'; // Green
      case RequestStatus.rejected:
        return '#D32F2F'; // Red
    }
  }
}

// ─── Model yêu cầu ───────────────────────────────────────────────────────────
// Firestore path: /requests/{requestId}
class RequestModel {
  final String id;
  // Thông tin sinh viên tạo yêu cầu
  final String studentUid;
  final String studentName;
  final String studentId;   // Mã số sinh viên
  // Thông tin danh mục
  final String categoryId;
  final String categoryName;
  // Nội dung yêu cầu
  final String reason;
  final List<String> attachmentUrls; // URL ảnh đính kèm trên Supabase Storage
  // Trạng thái xử lý
  final RequestStatus status;
  final String? note;       // Phản hồi từ Giáo vụ khoa
  final String? staffUid;   // UID của cán bộ xử lý
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const RequestModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentId,
    required this.categoryId,
    required this.categoryName,
    required this.reason,
    required this.attachmentUrls,
    required this.status,
    this.note,
    this.staffUid,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Từ Firestore Document → RequestModel ───────────────────────────────────
  factory RequestModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return RequestModel.fromMap(doc.id, map);
  }

  factory RequestModel.fromMap(String id, Map<String, dynamic> map) {
    return RequestModel(
      id: id,
      studentUid: map['studentUid'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      status: RequestStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      note: map['note'] as String?,
      staffUid: map['staffUid'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── RequestModel → Map để lưu lên Firestore ────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'studentId': studentId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'reason': reason,
      'attachmentUrls': attachmentUrls,
      'status': status.name,
      'note': note,
      'staffUid': staffUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // ── Cập nhật trạng thái (Giáo vụ dùng) ────────────────────────────────────
  RequestModel copyWithStatus({
    required RequestStatus status,
    required String staffUid,
    String? note,
  }) {
    return RequestModel(
      id: id,
      studentUid: studentUid,
      studentName: studentName,
      studentId: studentId,
      categoryId: categoryId,
      categoryName: categoryName,
      reason: reason,
      attachmentUrls: attachmentUrls,
      status: status,
      note: note ?? this.note,
      staffUid: staffUid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
