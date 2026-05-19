import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/screens/student/main_navigation.dart';
import 'package:huit_student_request_app/ui/widgets/custom_loading.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../state/auth_provider.dart';
import 'package:huit_student_request_app/ui/widgets/glass_toast.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:huit_student_request_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mssvController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _rememberMe = false; // Thêm biến cho checkbox

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // Gọi hàm nạp MSSV khi mở trang
  }

  // Hàm nạp dữ liệu đã ghi nhớ
  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _mssvController.text = prefs.getString('saved_mssv') ?? '';
      }
    });
  }

  @override
  void dispose() {
    _mssvController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC GỐC LÚC CHƯA LÀM HYPEROS ---
  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    
    final mssv = _mssvController.text.trim();
    final password = _passwordController.text.trim();

    if (mssv.isEmpty || password.isEmpty) {
      GlassToast.show(context, 'Vui lòng nhập đầy đủ MSSV và Mật khẩu!', isError: true);
      return;
    }

    final emailForSupabase = mssv.contains('@') ? mssv : '$mssv@hdpe.edu.vn';

    try {
      // Gọi đăng nhập
      await context.read<AuthProvider>().signIn(emailForSupabase, password);
      if (!mounted) return;
      // KIỂM TRA LẠI: Chỉ hiện thành công nếu user thực sự đã được xác thực
      final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
      
      if (isAuthenticated) {
        // GHI NHỚ ĐĂNG NHẬP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('saved_mssv', mssv);
        } else {
          await prefs.remove('saved_mssv');
        }

        // KÍCH HOẠT THÔNG BÁO ĐẨY REAL-TIME (Lấy uid trực tiếp từ Supabase)
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          // LẤY TOKEN VÀ ĐẨY LÊN SUPABASE NGAY KHI ĐĂNG NHẬP THÀNH CÔNG
          final fcmToken = await NotificationService.getFCMToken();
          if (fcmToken != null) {
            await Supabase.instance.client
                .from('users')
                .update({'fcm_token': fcmToken})
                .eq('uid', userId);
          }
        }

        // ─── Dùng MaterialPageRoute trực tiếp để tránh bị crash văng vào catch ───
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        }
        if (!mounted) return;
        GlassToast.show(context, 'Đăng nhập thành công! Chào mừng bạn.');
      } else {
        // Nếu không lỗi nhưng cũng không vào được (trường hợp hiếm)
        GlassToast.show(context, 'Mã số sinh viên hoặc mật khẩu không chính xác', isError: true);
      }
      
    } catch (e) {
      GlassToast.show(context, 'Lỗi gốc: ${e.toString()}', isError: true);
      debugPrint('LỖI SUPABASE: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          const _HyperOsBackground(),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6), 
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primarySV.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo.png', 
                          height: 110,
                          width: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gray900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập để quản lý yêu cầu của bạn',
                      style: TextStyle(fontSize: 15, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 40),

                    TextField(
                      controller: _mssvController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'Mã số sinh viên',
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primarySV),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.85),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        hintText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primarySV),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.gray500,
                          ),
                          onPressed: () => setState(() => _isObscure = !_isObscure),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.85),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // UI Ghi nhớ đăng nhập
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 24, height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.primarySV,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              child: const Text(
                                'Ghi nhớ đăng nhập',
                                style: TextStyle(color: AppColors.gray500, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Quên mật khẩu?', style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primarySV,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          shadowColor: AppColors.primarySV.withValues(alpha: 0.4),
                        ),
                        child: authState.isLoading
                            ? const CustomLoading() 
                            : const Text('Đăng nhập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= WIDGET NỀN HYPEROS BLUR =================
class _HyperOsBackground extends StatefulWidget {
  const _HyperOsBackground();

  @override
  State<_HyperOsBackground> createState() => _HyperOsBackgroundState();
}

class _HyperOsBackgroundState extends State<_HyperOsBackground> {
  late Timer _timer;
  final Random _random = Random();
  
  Alignment _align1 = const Alignment(0, 0);
  Alignment _align2 = const Alignment(0.5, -0.5);
  Alignment _align3 = const Alignment(-0.5, 0.5);

  @override
  void initState() {
    super.initState();
    _animateBlobs();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _animateBlobs();
    });
  }

  void _animateBlobs() {
    if (!mounted) return;
    setState(() {
      _align1 = Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
      _align2 = Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
      _align3 = Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), 
      child: Container(
        color: Colors.white.withValues(alpha: 0.1), 
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: _align1,
              duration: const Duration(seconds: 4),
              curve: Curves.easeInOutSine,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primarySV.withValues(alpha: 0.4)),
              ),
            ),
            AnimatedAlign(
              alignment: _align2,
              duration: const Duration(seconds: 5),
              curve: Curves.easeInOutSine,
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyan.withValues(alpha: 0.3)),
              ),
            ),
            AnimatedAlign(
              alignment: _align3,
              duration: const Duration(seconds: 6),
              curve: Curves.easeInOutSine,
              child: Container(
                width: 350, height: 350,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.indigoAccent.withValues(alpha: 0.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}