import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import thư viện
import '../../../core/theme.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Tự động chuyển trang sau 2.5 giây
    _checkRouting();
  }

  Future<void> _checkRouting() async {
    // 1. Chờ 2.5 giây để hiện logo
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // 2. Đọc dữ liệu từ bộ nhớ
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Nếu chưa từng lưu, giá trị mặc định sẽ là false
    bool seenOnboard = prefs.getBool('seenOnboard') ?? false;

    // 3. Quyết định chuyển trang
    if (mounted) {
      if (seenOnboard == true) {
        // Đã xem Onboarding -> Nhảy thẳng vào Đăng nhập
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Chưa xem -> Chuyển sang Onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Màu nền Gradient xanh dương
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B4A), Color(0xFF1A6BFF)],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🎓',
              style: TextStyle(fontSize: 60),
            ),
            SizedBox(height: 16),
            Text(
              'HDPE\nStudent Request',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Khoa Công nghệ Thông tin',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white), // Vòng xoay load
          ],
        ),
      ),
    );
  }
}