// lib/models/user_model.dart
// TV2 — Thiết kế cấu trúc dữ liệu người dùng (Task 2.2)

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enum phân loại vai trò người dùng ───────────────────────────────────────
enum UserRole { student, staff, admin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Sinh viên';
      case UserRole.staff:
        return 'Giáo vụ khoa';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }
}

// ─── Model người dùng ────────────────────────────────────────────────────────
// Firestore path: /users/{uid}
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? studentId;   // Mã số sinh viên (chỉ có với role=student)
  final String? fcmToken;    // Token để gửi Push Notification
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.studentId,
    this.fcmToken,
    required this.createdAt,
  });

  // ── Từ Firestore Document → UserModel ──────────────────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.student,
      ),
      studentId: map['studentId'] as String?,
      fcmToken: map['fcmToken'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── UserModel → Map để lưu lên Firestore ───────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'studentId': studentId,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ── Tạo bản sao với một số field thay đổi ──────────────────────────────────
  UserModel copyWith({
    String? displayName,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role,
      studentId: studentId,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
