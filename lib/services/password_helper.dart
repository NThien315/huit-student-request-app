// lib/services/password_helper.dart
// TV2 — Mã hóa & Kiểm tra mật khẩu (Password Hashing & Validation)
//
// ┌──────────────────────────────────────────────────────────────────────────┐
// │ GHI CHÚ QUAN TRỌNG:                                                    │
// │ Firebase Auth ĐÃ TỰ MÃ HÓA password bằng bcrypt/scrypt trên server.  │
// │ File này cung cấp thêm:                                                │
// │ 1. Validate password mạnh trước khi gửi lên Firebase                  │
// │ 2. Hash password bằng SHA-256 để lưu log audit (không lưu plaintext)  │
// │ 3. Utility kiểm tra password match khi cần so sánh local              │
// └──────────────────────────────────────────────────────────────────────────┘

import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHelper {
  // ════════════════════════════════════════════════════════════════════════════
  // MÃ HÓA PASSWORD (SHA-256 Hash)
  // Dùng khi: Log audit, so sánh local, không bao giờ lưu plaintext
  // ════════════════════════════════════════════════════════════════════════════

  /// Mã hóa password bằng SHA-256
  /// Trả về chuỗi hash hex 64 ký tự
  ///
  /// ```dart
  /// final hash = PasswordHelper.hashPassword('MyP@ssw0rd');
  /// // → '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8'
  /// ```
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Mã hóa password với salt (an toàn hơn)
  /// Salt = email hoặc uid của user, đảm bảo cùng password khác user → hash khác
  ///
  /// ```dart
  /// final hash = PasswordHelper.hashWithSalt('MyP@ssw0rd', 'sv@huit.edu.vn');
  /// ```
  static String hashWithSalt(String password, String salt) {
    final salted = '$salt:$password';
    final bytes = utf8.encode(salted);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Kiểm tra password có khớp với hash đã lưu không
  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  /// Kiểm tra password có khớp với hash+salt không
  static bool verifyWithSalt(String password, String salt, String hashedPassword) {
    return hashWithSalt(password, salt) == hashedPassword;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // VALIDATE ĐỘ MẠNH PASSWORD
  // Đảm bảo password đủ mạnh trước khi gửi lên Firebase Auth
  // ════════════════════════════════════════════════════════════════════════════

  /// Kiểm tra password có đạt yêu cầu bảo mật không
  /// Trả về null nếu hợp lệ, trả về thông báo lỗi nếu không
  ///
  /// Yêu cầu:
  /// - Tối thiểu 6 ký tự (Firebase Auth yêu cầu)
  /// - Có ít nhất 1 chữ hoa
  /// - Có ít nhất 1 chữ thường
  /// - Có ít nhất 1 chữ số
  ///
  /// ```dart
  /// final error = PasswordHelper.validatePassword('abc');
  /// // → 'Mật khẩu phải có ít nhất 6 ký tự'
  ///
  /// final error2 = PasswordHelper.validatePassword('Abc12345');
  /// // → null (hợp lệ)
  /// ```
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ in hoa';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ số';
    }
    return null; // Password hợp lệ
  }

  /// Đánh giá độ mạnh của password
  /// Trả về: 'weak' | 'medium' | 'strong'
  static String getPasswordStrength(String password) {
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) return 'weak';
    if (score <= 4) return 'medium';
    return 'strong';
  }

  /// Nhãn tiếng Việt cho độ mạnh password
  static String getStrengthLabel(String strength) {
    switch (strength) {
      case 'weak':
        return 'Yếu';
      case 'medium':
        return 'Trung bình';
      case 'strong':
        return 'Mạnh';
      default:
        return '';
    }
  }
}
