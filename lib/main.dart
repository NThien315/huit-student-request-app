// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxaXdzZWtpem93YWtsbXhnaGt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NzY2NzEsImV4cCI6MjA5NDI1MjY3MX0.ZrzgIpOa474j7kn_gOHIdPBykig4XiU2Wt3Gd3hpCnk',
  );

  // 2. Khởi tạo Firebase (Dùng cho Push Notification)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Khởi tạo Dịch vụ Thông báo
  try {
    await NotificationService.initNotification();
  } catch (e) {
    debugPrint("Bỏ qua lỗi khởi tạo Notification: $e");
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
      ],
      child: MaterialApp(
        title: 'HDPE – Hỗ trợ Sinh viên',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, 
        
        home: const SplashScreen(), 
      ),
    );
  }
}