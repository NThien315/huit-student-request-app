import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/screens/admin/admin_layout.dart';
import 'package:huit_student_request_app/ui/screens/staff/staff_layout.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thêm thư viện lưu trữ
import '../../../core/theme.dart';
import '../../../state/auth_provider.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false; 
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // Tự động nạp email đã lưu khi mở trang web
  }

  // Hàm nạp dữ liệu ghi nhớ đăng nhập từ bộ nhớ trình duyệt
  void _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('web_remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('saved_web_email') ?? '';
      }
    });
  }

  Future<void> _handleWebLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await context.read<AuthProvider>().signIn(email, password);

      if (!mounted) return;
      final isAuthenticated = context.read<AuthProvider>().isAuthenticated;

      if (isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('web_remember_me', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('saved_web_email', email);
        } else {
          await prefs.remove('saved_web_email');
        }

        if (mounted) {
          final userModel = context.read<AuthProvider>().currentUser;
          final String roleString = userModel?.role.toString().split('.').last ?? 'student';

          if (roleString == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLayout()));
          } else if (roleString == 'staff') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StaffLayout()));
          } else {
            // Chặn sinh viên
            context.read<AuthProvider>().signOut();
            // Nếu có WebToast thì gọi ở đây, tuyệt đối bỏ GlassToast
            WebToast.show(context, 'Sinh viên không được truy cập Web!', isError: true);
          }
        }
      } else {
        WebToast.show(context, 'Tài khoản hoặc mật khẩu sai!', isError: true);
      }
    } catch (e) {
      if (mounted) {
        WebToast.show(context, 'Đăng nhập thất bại: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _HyperOsBackground(), 
          
          Row(
            children: [
              // ─── NỬA BÊN TRÁI: PANEL THƯƠNG HIỆU (ĐÃ ĐỔI LOGO TRƯỜNG) ───
              if (screenSize.width > 800) 
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // LOGO TRƯỜNG ĐÃ ĐƯỢC CẬP NHẬT TẠI ĐÂY
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.gray200, width: 1),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/huit_logo.png', 
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Khoa Công nghệ Thông tin\nĐại học Công Thương TP.HCM',
                              style: TextStyle(color: AppColors.gray500, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        
                        const Text(
                          'HỆ THỐNG QUẢN TRỊ\nHDPE STUDENT REQUEST',
                          style: TextStyle(color: AppColors.gray900, fontSize: 40, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.format_quote_rounded, size: 36, color: AppColors.primarySV.withValues(alpha: 0.5)),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Chuyển đổi số toàn diện công tác học vụ. Tối ưu hóa quy trình tiếp nhận, xử lý minh bạch và nâng cao trải nghiệm của sinh viên toàn khoa.',
                                  style: TextStyle(color: AppColors.gray900, fontSize: 16, height: 1.6, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        _buildFeatureItem(Icons.speed_rounded, 'Tự động hóa quy trình phân luồng yêu cầu'),
                        const SizedBox(height: 16),
                        _buildFeatureItem(Icons.security_rounded, 'Lưu trữ đám mây an toàn & bảo mật'),
                        const SizedBox(height: 16),
                        _buildFeatureItem(Icons.analytics_rounded, 'Báo cáo thống kê hiệu suất theo thời gian thực'),
                      ],
                    ),
                  ),
                ),

              // ─── NỬA BÊN PHẢI: FORM ĐĂNG NHẬP ───
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 50, spreadRadius: 5, offset: const Offset(-10, 0)),
                    ],
                    border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5)),
                  ),
                  child: ClipRect( 
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), 
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.45), 
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 40.0),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                      child: const Text('👋 Chào mừng trở lại', style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text('Đăng nhập hệ thống', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                    const SizedBox(height: 8),
                                    const Text('Vui lòng sử dụng tài khoản công tác được cấp.', style: TextStyle(color: AppColors.gray500, fontSize: 15)),
                                    const SizedBox(height: 40),

                                    const Text('Email công tác', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        hintText: 'name@huit.edu.vn',
                                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primarySV),
                                        filled: true,
                                        fillColor: Colors.white.withValues(alpha: 0.7),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    const Text('Mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primarySV),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.gray500),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withValues(alpha: 0.7),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {}, 
                                        child: const Text('Quên mật khẩu?', style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold))
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primarySV,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          elevation: 3,
                                          shadowColor: AppColors.primarySV.withValues(alpha: 0.5),
                                        ),
                                        onPressed: _isLoading ? null : _handleWebLogin,
                                        child: _isLoading
                                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                            : const Text('ĐĂNG NHẬP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                      ),
                                    ),

                                    const SizedBox(height: 48),
                                    const Divider(color: Colors.black12, height: 1),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: const TextSpan(
                                          style: TextStyle(color: AppColors.gray500, fontSize: 13, height: 1.5),
                                          children: [
                                            TextSpan(text: 'Trải nghiệm sự cố? Liên hệ Hỗ trợ kỹ thuật tại\n'),
                                            TextSpan(text: 'support@fit.huit.edu.vn', style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold)),
                                          ]
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primarySV, size: 20),
        ),
        const SizedBox(width: 16),
        Text(text, style: const TextStyle(color: AppColors.gray900, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ================= WIDGET NỀN HYPEROS BLUR (5 BONG BÓNG) =================
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
  Alignment _align4 = const Alignment(0.8, 0.8);
  Alignment _align5 = const Alignment(-0.8, -0.8);

  @override
  void initState() {
    super.initState();
    _animateBlobs();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _animateBlobs();
    });
  }

  void _animateBlobs() {
    if (!mounted) return;
    setState(() {
      _align1 = Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
      _align2 = Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
      _align3 = Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
      _align4 = Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
      _align5 = Alignment(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1);
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
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), 
      child: Container(
        color: Colors.white.withValues(alpha: 0.1), 
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: _align1,
              duration: const Duration(seconds: 6),
              curve: Curves.easeInOutSine,
              child: Container(width: 450, height: 450, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primarySV.withValues(alpha: 0.35))),
            ),
            AnimatedAlign(
              alignment: _align2,
              duration: const Duration(seconds: 5),
              curve: Curves.easeInOutSine,
              child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.cyan.withValues(alpha: 0.25))),
            ),
            AnimatedAlign(
              alignment: _align3,
              duration: const Duration(seconds: 7),
              curve: Curves.easeInOutSine,
              child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.indigoAccent.withValues(alpha: 0.2))),
            ),
            AnimatedAlign(
              alignment: _align4,
              duration: const Duration(seconds: 8),
              curve: Curves.easeInOutSine,
              child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withValues(alpha: 0.2))),
            ),
            AnimatedAlign(
              alignment: _align5,
              duration: const Duration(seconds: 6),
              curve: Curves.easeInOutSine,
              child: Container(width: 420, height: 420, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withValues(alpha: 0.15))),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= WIDGET THÔNG BÁO WEB TOAST  =================
class WebToast {
  static void show(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 32,
        right: 32,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isError ? Colors.red.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8)),
                ],
                border: Border.all(
                  color: isError ? Colors.red.shade200 : AppColors.gray200, 
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: isError ? Colors.redAccent : Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: isError ? Colors.red.shade900 : AppColors.gray900,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    // Tự động tắt sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }
}