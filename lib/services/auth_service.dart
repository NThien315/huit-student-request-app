import '../models/user_model.dart';

class AuthService {
  Future<UserModel> loginWithFirebase(String mssv, String password) async {
    // Giả lập thời gian chờ
    await Future.delayed(const Duration(seconds: 1));

    if (mssv == '2001230534') {
      return UserModel(mssv: mssv, name: 'Trần Tiến Hoài Nam');
    }
    throw Exception('Sai mật khẩu');
  }
}
