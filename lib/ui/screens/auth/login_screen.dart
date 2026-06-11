import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../core/theme.dart';
import '../../../state/auth_provider.dart';
import 'package:huit_student_request_app/ui/widgets/glass_toast.dart';
import 'package:huit_student_request_app/services/notification_service.dart';

// IMPORT CÁC LUỒNG ĐỂ ĐIỀU HƯỚNG
import 'package:huit_student_request_app/ui/screens/student/main_navigation.dart';
import '../admin/admin_layout.dart';
import '../staff/staff_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mssvController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _rememberMe = false; 

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); 
  }

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

  // ─── LOGIC ĐĂNG NHẬP RẼ NHÁNH THEO QUYỀN HẠN ───
  void _handleLogin() async {
    FocusScope.of(context).unfocus();
    
    final mssv = _mssvController.text.trim();
    final password = _passwordController.text.trim();

    if (mssv.isEmpty || password.isEmpty) {
      GlassToast.show(context, 'Vui lòng nhập đầy đủ Tài khoản và Mật khẩu!', isError: true);
      return;
    }

    final emailForSupabase = mssv.contains('@') ? mssv : '$mssv@hdpe.edu.vn';

    try {
      await context.read<AuthProvider>().signIn(emailForSupabase, password);
      if (!mounted) return;
      
      final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
      
      if (isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('saved_mssv', mssv);
        } else {
          await prefs.remove('saved_mssv');
        }

        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          // 1. Phân quyền rẽ nhánh
          final userData = await Supabase.instance.client.from('users').select('role').eq('uid', userId).maybeSingle();
          final role = userData?['role']?.toString().toLowerCase() ?? 'student';

          // 2. Kích hoạt Push Notification
          final fcmToken = await NotificationService.getFCMToken();
          if (fcmToken != null) {
            await Supabase.instance.client.from('users').update({'fcm_token': fcmToken}).eq('uid', userId);
          }

          // Ghi log đăng nhập trực tiếp
          try {
            await Supabase.instance.client.from('audit_logs').insert({
              'actor_name': mssv, 
              'actor_email': emailForSupabase,
              'action_type': 'LOGIN',
              'target_name': 'Hệ thống HDPE',
              'details': 'Đăng nhập thành công vào luồng: ${role.toUpperCase()}',
            });
          } catch (_) {}

          if (!mounted) return;
          // 3. Điều hướng mượt mà
          if (role == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLayout()));
          } else if (role == 'staff') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StaffLayout()));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
          }
          GlassToast.show(context, 'Đăng nhập thành công! Chào mừng bạn.');
        }
      } else {
        GlassToast.show(context, 'Tài khoản hoặc mật khẩu không chính xác', isError: true);
      }
    } catch (e) {
      GlassToast.show(context, 'Đăng nhập thất bại, vui lòng thử lại!', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>();

    // ─── KHỐI FORM ĐĂNG NHẬP (Dùng chung cho cả Mobile & Web) ───
    Widget loginForm = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.primarySV.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/logo.png', height: 110, width: 110, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.school, size: 80, color: AppColors.primarySV)),
                ),
              ),
              const SizedBox(height: 32),

              const Text('Đăng nhập hệ thống', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              const SizedBox(height: 8),
              const Text('Vui lòng sử dụng tài khoản được cấp', style: TextStyle(fontSize: 15, color: AppColors.gray500)),
              const SizedBox(height: 40),

              TextField(
                controller: _mssvController, keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Tài khoản hoặc Mã số', prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primarySV),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.85),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController, obscureText: _isObscure,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu', prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primarySV),
                  suffixIcon: IconButton(icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: AppColors.gray500), onPressed: () => setState(() => _isObscure = !_isObscure)),
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.85),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // FIX LỖI TRÀN NGANG CHỖ QUÊN MẬT KHẨU BẰNG WRAP
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 24, height: 24, child: Checkbox(value: _rememberMe, activeColor: AppColors.primarySV, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), onChanged: (value) => setState(() => _rememberMe = value ?? false))),
                      const SizedBox(width: 8),
                      GestureDetector(onTap: () => setState(() => _rememberMe = !_rememberMe), child: const Text('Ghi nhớ đăng nhập', style: TextStyle(color: AppColors.gray500, fontSize: 14, fontWeight: FontWeight.w500))),
                    ],
                  ),
                  TextButton(onPressed: () {}, child: const Text('Quên mật khẩu?', style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold)))
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySV, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5, shadowColor: AppColors.primarySV.withValues(alpha: 0.4)),
                  child: authState.isLoading ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Đăng nhập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, 
      // ─── LAYOUT BUILDER LÀM RESPONSIVE (TỰ BẺ GIAO DIỆN) ───
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          if (isDesktop) {
            // Chia đôi Split Screen
            return Row(
              children: [
                Expanded(flex: 5, child: _buildLeftBanner()),
                Expanded(flex: 4, child: Stack(children: [const _HyperOsBackground(), loginForm])),
              ],
            );
          }

          // MÀN HÌNH ĐIỆN THOẠI: Ẩn Banner, Giữ Form
          return Stack(
            children: [
              const _HyperOsBackground(),
              SafeArea(child: loginForm),
            ],
          );
        },
      ),
    );
  }

  // ─── KHỐI BANNER BÊN TRÁI ───
  Widget _buildLeftBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Color(0xFFEBF4FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border(right: BorderSide(color: AppColors.gray200)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.school_rounded, color: AppColors.primarySV, size: 32)),
                const SizedBox(width: 16),
                const Expanded(child: Text('Khoa Công nghệ Thông tin\nĐại học Công Thương TP.HCM', style: TextStyle(color: AppColors.gray500, fontWeight: FontWeight.bold, fontSize: 14))),
              ],
            ),
            const SizedBox(height: 60),
            const Text('HỆ THỐNG\nQUẢN TRỊ\nHDPE STUDENT\nREQUEST', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, height: 1.1, color: AppColors.gray900)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded, color: AppColors.primarySV, size: 32),
                  SizedBox(width: 16),
                  Expanded(child: Text('Chuyển đổi số toàn diện công tác học vụ. Tối ưu hóa quy trình tiếp nhận, xử lý minh bạch và nâng cao trải nghiệm của sinh viên toàn khoa.', style: TextStyle(fontSize: 16, height: 1.6, color: AppColors.gray900, fontStyle: FontStyle.italic))),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureLine(Icons.speed_rounded, 'Tự động hóa quy trình phân luồng yêu cầu'),
            _buildFeatureLine(Icons.cloud_done_rounded, 'Lưu trữ đám mây an toàn & bảo mật'),
            _buildFeatureLine(Icons.insert_chart_rounded, 'Báo cáo thống kê hiệu suất theo thời gian thực'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(children: [Icon(icon, color: AppColors.primarySV, size: 20), const SizedBox(width: 16), Expanded(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray900)))]),
    );
  }
}

class _HyperOsBackground extends StatefulWidget {
  const _HyperOsBackground();
  @override
  State<_HyperOsBackground> createState() => _HyperOsBackgroundState();
}
class _HyperOsBackgroundState extends State<_HyperOsBackground> {
  late Timer _timer; final Random _random = Random();
  Alignment _align1 = const Alignment(0, 0); Alignment _align2 = const Alignment(0.5, -0.5); Alignment _align3 = const Alignment(-0.5, 0.5);

  @override
  void initState() {
    super.initState();
    _animateBlobs();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) => _animateBlobs());
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
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), 
      child: Container(
        color: Colors.white.withValues(alpha: 0.1), 
        child: Stack(
          children: [
            AnimatedAlign(alignment: _align1, duration: const Duration(seconds: 4), curve: Curves.easeInOutSine, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primarySV.withValues(alpha: 0.4)))),
            AnimatedAlign(alignment: _align2, duration: const Duration(seconds: 5), curve: Curves.easeInOutSine, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyan.withValues(alpha: 0.3)))),
            AnimatedAlign(alignment: _align3, duration: const Duration(seconds: 6), curve: Curves.easeInOutSine, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.indigoAccent.withValues(alpha: 0.2)))),
          ],
        ),
      ),
    );
  }
}