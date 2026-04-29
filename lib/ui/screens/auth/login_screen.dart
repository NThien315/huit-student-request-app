import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Biến lưu trạng thái đang chọn Sinh viên (true) hay Giáo vụ (false)
  bool isStudent = true; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Ảnh minh họa phía trên (Placeholder)
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  color: AppColors.lightSV,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: AppColors.primarySV,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              const Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 20),

              // Thanh Toggle Sinh viên / Giáo vụ Khoa
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isStudent = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isStudent ? AppColors.white : Colors.transparent,
                            boxShadow: isStudent 
                                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] 
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sinh viên',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isStudent ? AppColors.gray900 : AppColors.gray500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isStudent = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isStudent ? AppColors.white : Colors.transparent,
                            boxShadow: !isStudent 
                                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] 
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Giáo vụ Khoa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !isStudent ? AppColors.gray900 : AppColors.gray500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ô nhập liệu tự động đổi text theo Role
              CustomTextField(
                label: isStudent ? 'Mã số sinh viên' : 'Mã cán bộ / Email',
                hintText: isStudent ? 'Nhập mã số sinh viên' : 'Nhập mã cán bộ hoặc email',
                prefixIcon: Icons.person_outline,
              ),
              
              const CustomTextField(
                label: 'Mật khẩu',
                hintText: 'Nhập mật khẩu',
                isPassword: true,
                prefixIcon: Icons.lock_outline,
              ),

              // Quên mật khẩu
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    // TODO: Chuyển sang trang Quên mật khẩu
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                      color: isStudent ? AppColors.primarySV : AppColors.primaryGV,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nút đăng nhập đổi màu theo Role
              CustomButton(
                text: 'Đăng nhập',
                backgroundColor: isStudent ? AppColors.primarySV : AppColors.primaryGV,
                onPressed: () {
                  // TODO: Xử lý logic đăng nhập với TV2
                  print('Đang đăng nhập với quyền: ${isStudent ? "Sinh viên" : "Giáo vụ"}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}