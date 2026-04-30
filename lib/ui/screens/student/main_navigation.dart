import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'home_screen.dart'; 

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Danh sách 5 màn hình
  final List<Widget> _screens = [
    const HomeScreen(), // Tab 0: Trang chủ giao diện thật
    const Center(child: Text('⏳ Màn hình Lịch sử')), // Tab 1
    const Center(child: Text('➕ Màn hình Tạo yêu cầu mới')), // Tab 2
    const Center(child: Text('🔔 Màn hình Thông báo')), // Tab 3
    const Center(child: Text('👤 Màn hình Cá nhân')), // Tab 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primarySV,
        unselectedItemColor: AppColors.gray500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 28), activeIcon: Icon(Icons.add_circle, size: 28), label: 'Tạo yêu cầu'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_outlined), activeIcon: Icon(Icons.notifications), label: 'Thông báo'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Cá nhân'), // Dùng icon Răng cưa giống thiết kế
        ],
      ),
    );
  }
}