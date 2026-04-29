import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Dữ liệu 3 màn hình Onboarding
  final List<Map<String, String>> onboardingData = [
    {
      "icon": "📱",
      "title": "Gửi yêu cầu\nmọi lúc mọi nơi",
      "desc": "Không cần đến trực tiếp văn phòng. Gửi yêu cầu giấy tờ ngay trên điện thoại của bạn.",
    },
    {
      "icon": "📊",
      "title": "Theo dõi tiến độ\ntheo thời gian thực",
      "desc": "Biết ngay khi yêu cầu được tiếp nhận, đang xử lý hay đã hoàn thành qua thông báo push.",
    },
    {
      "icon": "🔔",
      "title": "Nhận thông báo\ntức thì",
      "desc": "Nhận push notification ngay khi có cập nhật mới. Không bỏ lỡ bất kỳ thông tin nào từ khoa.",
    }
  ];

  Future<void> _finishOnboarding() async {
    // Gọi bộ nhớ ra và lưu cờ 'seenOnboard' = true
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboard', true);

    // Kiểm tra mounted (bắt buộc trong Flutter khi dùng async/await với context)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Nút Bỏ qua (Skip)
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text(
                  'Bỏ qua',
                  style: TextStyle(color: AppColors.gray500),
                ),
              ),
            ),
            
            // Nội dung vuốt ngang
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          onboardingData[index]["icon"]!,
                          style: const TextStyle(fontSize: 80),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          onboardingData[index]["desc"]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator (Các chấm tròn) & Nút Tiếp theo
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primarySV
                              : AppColors.gray200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == onboardingData.length - 1) {
                          _finishOnboarding(); // Trang cuối thì vào Đăng nhập
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySV,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Bạn có thể bỏ dòng này nếu muốn vuông góc
                        ),
                      ),
                      child: Text(
                        _currentPage == onboardingData.length - 1
                            ? '🚀 Bắt đầu ngay'
                            : 'Tiếp theo',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}