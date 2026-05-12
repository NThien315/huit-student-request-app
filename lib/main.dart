import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './state/auth_provider.dart';
import './state/request_provider.dart';

void main() {
  runApp(
    // Bọc MultiProvider ngoài cùng để toàn app có thể truy cập dữ liệu
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HUIT Student App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Tạm thời để một màn hình trắng, TV1 sẽ phụ trách ghép giao diện Login vào đây sau
      home: const Scaffold(
        body: Center(child: Text('Hệ thống Core đã sẵn sàng! Chờ TV1 ráp UI.')),
      ),
    );
  }
}
