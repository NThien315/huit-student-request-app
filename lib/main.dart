import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HDPE Student Request',
      debugShowCheckedModeBanner: false, // Tắt chữ DEBUG góc phải
      theme: AppTheme.lightTheme, // Gọi theme đã thiết lập ở Bước 1
      home: const SplashScreen(),
      //home: const LoginScreen(), // Mở thẳng màn hình Đăng nhập
    );
  }
}