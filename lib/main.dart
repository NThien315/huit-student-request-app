import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// UI của TV1
import 'package:huit_student_request_app/ui/screens/student/main_navigation.dart';
import 'core/theme.dart';
import 'ui/screens/auth/login_screen.dart';

// Dịch vụ Backend của TV2
import 'firebase_options.dart';
import 'state/auth_provider.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

import 'ui/screens/admin/admin_web_dashboard.dart';
import 'ui/screens/admin/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo Supabase (BẮT BUỘC ĐỂ KHÔNG CRASH APP)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', // Thay bằng URL thật của project Supabase
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // Thay bằng Anon Key thật
  );

  // Khởi tạo Push Notification (Bọc try-catch để lỡ thiếu config cũng không bị crash văng app)
  try {
    final notificationService = NotificationService(AuthService());
    await notificationService.initialize();
  } catch (e) {
    debugPrint("Bỏ qua lỗi khởi tạo Notification tạm thời: $e");
  }

  // Seed danh mục mẫu nếu Firestore chưa có dữ liệu
  try {
    await FirestoreService().seedCategories();
  } catch (e) {
    debugPrint("Bỏ qua lỗi seed data do chưa đăng nhập: $e");
  }

  runApp(const HdpeApp());
}

class HdpeApp extends StatelessWidget {
  const HdpeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Thêm các Provider khác ở đây khi TV3 hoàn thành State Management
      ],
      child: MaterialApp(
        title: 'HDPE – Hỗ trợ Sinh viên',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // QUAN TRỌNG: Gọi Trạm kiểm soát _AppEntry thay vì xông thẳng vào MainNavigation
        home: const _AppEntry(),
      ),
    );
  }
}

// ─── TRẠM KIỂM SOÁT ĐIỀU HƯỚNG THEO TRẠNG THÁI ĐĂNG NHẬP ────────────────────────────────
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    // Auto-login nếu còn session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Đang tải / Đang kiểm tra session -> Hiện vòng xoay
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primarySV),
        ),
      );
    }

    // 2. Nếu ĐÃ ĐĂNG NHẬP
    if (auth.isAuthenticated) {
      // ─ Phân luồng giao diện theo Role ─────────────────────────────────────────────
      if (auth.isStudent) {
        // Sinh viên -> Trả về giao diện xịn xò của TV1
        return const MainNavigation();
      } else if (auth.isStaff) {
        return const Scaffold(
          body: Center(child: Text('Giao diện Giáo vụ (Sẽ tích hợp sau)')),
        );
      } else {
        return const AdminWebDashboard();
      }
    }

    // 3. CHƯA ĐĂNG NHẬP -> Bắt ra cổng LoginScreen của TV1
    return const LoginScreen();
  }
}
