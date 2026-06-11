// lib/models/request_model.dart

enum RequestStatus { pending, processing, completed, rejected }

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending: return 'Chờ tiếp nhận';
      case RequestStatus.processing: return 'Đang xử lý';
      case RequestStatus.completed: return 'Đã hoàn thành';
      case RequestStatus.rejected: return 'Bị từ chối';
    }
  }

  String get colorHex {
    switch (this) {
      case RequestStatus.pending: return '#FFA000'; 
      case RequestStatus.processing: return '#1976D2'; 
      case RequestStatus.completed: return '#388E3C'; 
      case RequestStatus.rejected: return '#D32F2F'; 
    }
  }
}

class RequestModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String studentId;   
  final String categoryId;
  final String categoryName;
  final String reason;
  final List<String> attachmentUrls; 
  final List<String>? attachedFiles; 
  final RequestStatus status;
  final String? note;       
  final String? staffUid;   
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? subjectCode;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final DateTime? rejectedAt;

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
    this.attachedFiles,
    required this.createdAt,
    required this.updatedAt,
    this.subjectCode,
    this.processedAt,
    this.completedAt,
    this.rejectedAt,
  });

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null) return DateTime.now();
      return DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
    }

    return RequestModel(
      id: map['id']?.toString() ?? '',
      studentUid: map['studentUid']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      categoryName: map['categoryName']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      attachmentUrls: map['attachmentUrls'] != null ? List<String>.from(map['attachmentUrls']) : [],
      status: RequestStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RequestStatus.pending,
      ),
      note: map['note']?.toString(),
      staffUid: map['staffUid']?.toString(),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      attachedFiles: map['attachedFiles'] != null ? List<String>.from(map['attachedFiles']) : [],
      subjectCode: map['subjectCode']?.toString(),
      processedAt: map['processedAt'] != null ? DateTime.tryParse(map['processedAt'].toString()) : null,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt'].toString()) : null,
      rejectedAt: map['rejectedAt'] != null ? DateTime.tryParse(map['rejectedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'studentId': studentId,
      'categoryId': int.tryParse(categoryId.toString()) ?? 1, 
      'categoryName': categoryName,
      'reason': reason,
      'attachmentUrls': attachmentUrls,
      'status': status.name,
      'note': note,
      'staffUid': staffUid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachedFiles': attachedFiles,
      'subjectCode': subjectCode,
      'processedAt': processedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
    };
  }
}