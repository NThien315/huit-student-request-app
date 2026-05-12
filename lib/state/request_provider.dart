import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../services/db_service.dart';

class RequestProvider extends ChangeNotifier {
  final DbService _dbService = DbService();

  List<RequestModel> _requests = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<RequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadStudentRequests(String mssv) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _requests = await _dbService.fetchRequestsFromFirestore(mssv);
    } catch (e) {
      _errorMessage = 'Lỗi hệ thống: Không thể tải đơn từ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
