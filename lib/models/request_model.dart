class RequestModel {
  final String id;
  final String studentId;
  final String requestType;
  final String status;

  RequestModel({
    required this.id,
    required this.studentId,
    required this.requestType,
    required this.status,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json, String documentId) {
    return RequestModel(
      id: documentId,
      studentId: json['studentId'] ?? '',
      requestType: json['requestType'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}
