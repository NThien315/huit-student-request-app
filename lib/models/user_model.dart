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

  final String? className;   // Lớp
  final String? faculty;     // Khoa
  final String? major;       // Ngành
  final String? cohort;      // Khoá
  final String? trainingType;// Hệ đào tạo
  final String? phoneNumber; // Số điện thoại
  final String? idCard;      // Số CCCD
  final String? address;     // Địa chỉ

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.studentId,
    this.fcmToken,
    required this.createdAt,
    this.className,
    this.faculty,
    this.major,
    this.cohort,
    this.trainingType,
    this.phoneNumber,
    this.idCard,
    this.address,
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
      
      // Map dữ liệu mới từ Firebase
      className: map['className'] as String?,
      faculty: map['faculty'] as String?,
      major: map['major'] as String?,
      cohort: map['cohort'] as String?,
      trainingType: map['trainingType'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      idCard: map['idCard'] as String?,
      address: map['address'] as String?,
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
      
      // Đẩy dữ liệu mới lên Firebase
      'className': className,
      'faculty': faculty,
      'major': major,
      'cohort': cohort,
      'trainingType': trainingType,
      'phoneNumber': phoneNumber,
      'idCard': idCard,
      'address': address,
    };
  }

  // ── Tạo bản sao với một số field thay đổi ──────────────────────────────────
  UserModel copyWith({
    String? displayName,
    String? fcmToken,
    String? className,
    String? faculty,
    String? major,
    String? cohort,
    String? trainingType,
    String? phoneNumber,
    String? idCard,
    String? address,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role,
      studentId: studentId,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      className: className ?? this.className,
      faculty: faculty ?? this.faculty,
      major: major ?? this.major,
      cohort: cohort ?? this.cohort,
      trainingType: trainingType ?? this.trainingType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      idCard: idCard ?? this.idCard,
      address: address ?? this.address,
    );
  }
}