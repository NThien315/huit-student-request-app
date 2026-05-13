// lib/main.dart
// Entry point — TV2 phụ trách setup Firebase và Provider

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Auto-generated bởi flutterfire configure
import 'core/constants.dart';
import 'state/auth_provider.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase (Auth, Firestore, FCM)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Supabase (chỉ dùng cho Storage — thay Firebase Storage)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Khởi tạo Push Notification
  final notificationService = NotificationService(AuthService());
  await notificationService.initialize();

  // Seed danh mục mẫu nếu Firestore chưa có dữ liệu
  await FirestoreService().seedCategories();

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0), // Xanh dương khoa CNTT
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const _AppEntry(),
      ),
    );
  }
}

// ─── Kiểm tra trạng thái đăng nhập khi app mở ────────────────────────────────
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

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isAuthenticated) {
      // ─ Điều hướng theo role ─────────────────────────────────────────────
      // TODO: TV1 implement các màn hình UI, TV2 chỉ cần cung cấp auth.isStudent / isStaff / isAdmin
      if (auth.isStudent) {
        return const Scaffold(
          body: Center(child: Text('Màn hình Sinh viên — TV1 implement')),
        );
      } else if (auth.isStaff) {
        return const Scaffold(
          body: Center(child: Text('Màn hình Giáo vụ — TV1 implement')),
        );
      } else {
        return const Scaffold(
          body: Center(child: Text('Màn hình Admin — TV1 implement')),
        );
      }
    }

    // Chưa đăng nhập → màn hình Login (TV1 implement UI, TV2 cung cấp service)
    return const Scaffold(
      body: Center(child: Text('Màn hình Đăng nhập — TV1 implement UI')),
    );
  }
}
