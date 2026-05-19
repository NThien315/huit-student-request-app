import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.isPassword = false,
    this.prefixIcon,
    this.controller,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true; // Biến để theo dõi trạng thái ẩn/hiện mật khẩu

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label nằm trên ô nhập
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        
        // Ô nhập liệu
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: AppColors.gray500, fontSize: 14),
            // Icon bên trái
            prefixIcon: widget.prefixIcon != null 
                ? Icon(widget.prefixIcon, color: AppColors.gray500, size: 22) 
                : null,
            // Icon con mắt bên phải (Chỉ hiện nếu là ô nhập mật khẩu)
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.gray500,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText; // Đảo trạng thái con mắt
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.white, 
            // Trạng thái bình thường
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gray200, width: 1.5),
            ),
            // Trạng thái khi đang click vào để gõ chữ (Viền xanh)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primarySV, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 16), // Khoảng cách đẩy xuống dưới
      ],
    );
  }
}