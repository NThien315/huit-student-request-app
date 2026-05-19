import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Nút tràn viền ngang
      height: 48, // Chiều cao 
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          // Nếu không truyền màu, mặc định lấy màu Xanh Sinh Viên
          backgroundColor: backgroundColor ?? AppColors.primarySV,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Bo góc 12px
          ),
          elevation: 0, // Bỏ bóng đổ
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}