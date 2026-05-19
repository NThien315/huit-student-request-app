import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/screens/student/create_request_screen.dart';
import 'package:huit_student_request_app/ui/screens/student/notification_screen.dart';
import 'package:huit_student_request_app/ui/screens/student/profile_screen.dart';
import '../../../core/theme.dart';
import 'home_screen.dart'; 
import 'history_screen.dart';                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cho phép nội dung cuộn bên dưới NavBar
      extendBody: true, 
      backgroundColor: AppColors.white,
      
      body: IndexedStack(
        index: _selectedIndex, // Lấy vị trí tab hiện tại
        children: const [
          HomeScreen(),
          HistoryScreen(),
          CreateRequestScreen(),
          NotificationScreen(),
          ProfileScreen(),
        ],
      ),
      // ───────────────────────────────────────────────────────
      
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

Widget _buildFloatingNavBar() {
  final screenWidth = MediaQuery.of(context).size.width;
  final marginHorizontal = 60.0; 
  final availableWidth = screenWidth - marginHorizontal;
  final tabWidth = (availableWidth - 16) / 5; 

  return Container(
    margin: const EdgeInsets.fromLTRB(30, 0, 30, 35),
    height: 65,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(40),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 25,
          spreadRadius: 1,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        // Hiệu ứng nền xanh trượt (Sliding Pill)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400), // Tăng nhẹ thời gian để mượt hơn
          curve: Curves.easeInOutCubic, 
          left: 8 + (_selectedIndex * tabWidth),
          top: 8,
          bottom: 8,
          width: tabWidth,
          child: Container(
            decoration: BoxDecoration(
              // Đảm bảo màu sắc và bo góc đồng bộ
              color: AppColors.primarySV.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        // Các Tab Icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home', tabWidth),
              _buildNavItem(1, Icons.history_rounded, Icons.history_outlined, 'Lịch sử', tabWidth),
              _buildNavItem(2, Icons.add_circle_rounded, Icons.add_circle_outline_rounded, 'Tạo đơn', tabWidth),
              _buildNavItem(3, Icons.notifications_rounded, Icons.notifications_none_rounded, 'Thông báo', tabWidth),
              _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Tôi', tabWidth),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, double tabWidth) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque, // Giúp bấm vào khoảng trống vẫn nhận lệnh
      child: SizedBox(
        width: tabWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.primarySV : AppColors.gray500,
              size: 24, // Size icon chuẩn
            ),
            const SizedBox(height: 2), // Ép icon và chữ sát lại với nhau
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primarySV : AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}