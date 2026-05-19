import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/screens/student/main_navigation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../services/notification_service.dart';
import '../../../state/auth_provider.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Bổ sung SingleTickerProviderStateMixin để chạy Animation
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // CẤU HÌNH HIỆU ỨNG CHUYỂN ĐỘNG (1.5 giây)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack)
    );
    
    _animationController.forward(); // Bắt đầu chạy hiệu ứng
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Kích hoạt dịch vụ thông báo ngầm
    await NotificationService.initNotification();

    final session = Supabase.instance.client.auth.currentSession;
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    // Bắt buộc dừng lại 2.2 giây để người dùng kịp ngắm logo và hiệu ứng
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    if (session != null && rememberMe) {
      await context.read<AuthProvider>().initAutoLogin();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } else {
      await Supabase.instance.client.auth.signOut();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.white, AppColors.primarySV.withValues(alpha: 0.08)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // ─── LOGO BO GÓC 3D CÓ ANIMATION ───
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36), 
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primarySV.withValues(alpha: 0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // ─── TÊN ỨNG DỤNG VÀ TRƯỜNG ───
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Column(
                children: [
                  Text(
                    'HDPE REQUEST',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppColors.primarySV,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Học Đến Phút End',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // ─── LOADING BOTTOM ───
            const CircularProgressIndicator(
              color: AppColors.primarySV,
              strokeWidth: 3.5,
            ),
            const SizedBox(height: 24),
            const Text(
              'Đang tải dữ liệu hệ thống...',
              style: TextStyle(color: AppColors.gray500, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}