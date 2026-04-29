import 'package:flutter/material.dart';

class AppColors {
  // Màu chủ đạo theo Role
  static const Color primarySV = Color(0xFF1A6BFF); // Xanh dương (Sinh viên)
  static const Color primaryGV = Color(0xFF6D28D9); // Tím (Giáo vụ)
  static const Color primaryAdmin = Color(0xFF0F172A); // Xanh đen (Admin)

  // Màu nền nhạt (Background nhạt cho icon/thẻ)
  static const Color lightSV = Color(0xFFE8F0FF);
  static const Color lightGV = Color(0xFFEDE9FE);

  // Màu Trạng thái (Status)
  static const Color success = Color(0xFF00B96B); // Hoàn thành
  static const Color successLight = Color(0xFFE0F7EE);
  
  static const Color warning = Color(0xFFFF8C00); // Chờ bổ sung
  static const Color warningLight = Color(0xFFFFF3E0);
  
  static const Color danger = Color(0xFFFF3B30); // Từ chối/Lỗi
  static const Color dangerLight = Color(0xFFFFECEB);

  // Màu Xám (Text, Border, Background)
  static const Color background = Color(0xFFEEF3FF); // Nền app chuẩn
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray100 = Color(0xFFF3F4F6); // Nền thẻ xám
  static const Color gray200 = Color(0xFFE5E7EB); // Viền (Border)
  static const Color gray500 = Color(0xFF6B7280); // Text phụ
  static const Color gray900 = Color(0xFF111827); // Text chính (Tiêu đề)
}

class AppTheme {
  // Gọi Theme chung cho toàn bộ App
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'BeVietnamPro',
      primaryColor: AppColors.primarySV,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.gray900),
        titleTextStyle: TextStyle(
          color: AppColors.gray900,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'BeVietnamPro',
        ),
      ),
    );
  }
}