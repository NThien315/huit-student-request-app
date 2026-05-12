import '../models/request_model.dart';

class DbService {
  Future<List<RequestModel>> fetchRequestsFromFirestore(String mssv) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      RequestModel(
        id: '1',
        studentId: mssv,
        requestType: 'Xin bảng điểm',
        status: 'Chờ duyệt',
      ),
    ];
  }
}
