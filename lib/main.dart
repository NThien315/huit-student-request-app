import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/screens/student/home_screen.dart';
import 'package:huit_student_request_app/ui/screens/student/main_navigation.dart';
import 'core/theme.dart';
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
      // home: const SplashScreen(),
      home: const MainNavigation(),
    );
  }
}