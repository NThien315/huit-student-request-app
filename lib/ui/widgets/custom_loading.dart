import 'package:flutter/material.dart';

// Tên class KHÔNG CÓ dấu gạch dưới -> Biến thành Public Class
class CustomLoading extends StatelessWidget {
  final Color color;
  final double size;

  // Thêm tùy chọn màu sắc và kích thước để bạn có thể linh hoạt dùng ở nhiều nơi khác nhau
  const CustomLoading({
    super.key, 
    this.color = Colors.white, // Mặc định là màu trắng (dùng cho nút bấm nền xanh)
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: color.withValues(alpha: 0.24), // Hiệu ứng 2 lớp màu
      ),
    );
  }
}