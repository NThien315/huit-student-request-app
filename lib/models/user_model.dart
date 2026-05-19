// lib/models/user_model.dart

enum UserRole { student, staff, admin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.student: return 'Sinh viên';
      case UserRole.staff: return 'Giáo vụ khoa';
      case UserRole.admin: return 'Quản trị viên';
    }
  }
}

// Supabase table: users
class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? studentId;   
  final String? fcmToken;    
  final DateTime createdAt;

  final String? className;   
  final String? faculty;     
  final String? major;       
  final String? cohort;      
  final String? trainingType;
  final String? phone; 
  final String? idCard;      
  final String? address;     

  const UserModel({
    required this.uid,
    required this.email,
    required this.name, 
    required this.role,
    this.studentId,
    this.fcmToken,
    required this.createdAt,
    this.className,
    this.faculty,
    this.major,
    this.cohort,
    this.trainingType,
    this.phone,
    this.idCard,
    this.address,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '', 
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.student,
      ),
      studentId: map['studentId'] as String?,
      fcmToken: map['fcmToken'] as String?,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      className: map['className'] as String?,
      faculty: map['faculty'] as String?,
      major: map['major'] as String?,
      cohort: map['cohort'] as String?,
      trainingType: map['trainingType'] as String?,
      phone: map['phone'] as String?,
      idCard: map['idCard'] as String?,
      address: map['address'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name, 
      'role': role.name,
      'studentId': studentId,
      'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
      'className': className,
      'faculty': faculty,
      'major': major,
      'cohort': cohort,
      'trainingType': trainingType,
      'phoneNumber': phone,
      'idCard': idCard,
      'address': address,
    };
  }
}