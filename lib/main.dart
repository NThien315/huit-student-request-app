// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:huit_student_request_app/ui/screens/auth/web_login_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'firebase_options.dart'; 
import 'state/auth_provider.dart';
import 'services/notification_service.dart';
import 'ui/screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Supabase
  await Supabase.initialize(
    url: 'https://eqiwsekizowaklmxghkw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxaXdzZWtpem93YWtsbXhnaGt3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3ODY3NjY3MSwiZXhwIjoyMDk0MjUyNjcxfQ.R7hv-o3NUTbI1W0CnIM29gGRXOdV9nZUF5Q9TNt9bfs',
  );

  // 2. Khởi tạo Firebase không chặn luồng
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Lỗi khởi tạo Firebase (Web): $e');
  }

  // 3. Khởi tạo Thông báo NHƯNG KHÔNG CHẶN luồng chính
  NotificationService.initNotification().catchError((e) {
    debugPrint("Bỏ qua lỗi khởi tạo Notification: $e");
  });

  runApp(const HdpeApp());
}

class HdpeApp extends StatelessWidget {
  const HdpeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'HDPE – Hỗ trợ Sinh viên',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, 
        
        home: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return const WebLoginScreen(); 
            } else {
              return const SplashScreen(); 
            }
          },
        ),
      ),
    );
  }
}

