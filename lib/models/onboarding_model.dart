class OnboardingContent {
  final String image;
  final String title;
  final String description;

  OnboardingContent({required this.image, required this.title, required this.description});
}

List<OnboardingContent> contents = [
  OnboardingContent(
    title: 'Hỗ trợ sinh viên HUIT',
    image: 'assets/images/onboarding_1.png', // Bạn hãy thêm ảnh minh họa vào assets nhé
    description: "Gửi các yêu cầu hành chính, học vụ đến khoa và nhà trường một cách nhanh chóng ngay trên điện thoại."
  ),
  OnboardingContent(
    title: 'Theo dõi tiến độ Realtime',
    image: 'assets/images/onboarding_2.png',
    description: "Cập nhật trạng thái xử lý yêu cầu 'Chờ tiếp nhận' đến 'Hoàn thành' theo thời gian thực."
  ),
  OnboardingContent(
    title: 'Cập nhật tin tức mới nhất',
    image: 'assets/images/onboarding_3.png',
    description: "Không bỏ lỡ các thông báo quan trọng về học bổng, học phí và lịch thi từ website nhà trường."
  ),
];