import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text('Thông báo', style: TextStyle(color: AppColors.gray900, fontSize: 18, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: const Icon(Icons.done_all, color: AppColors.primarySV, size: 22), onPressed: () {}),
          ],
          // TabBar lọc Tất cả / Chưa đọc chuẩn Figma
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                indicator: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                labelColor: AppColors.gray900,
                unselectedLabelColor: AppColors.gray500,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [Tab(text: 'Tất cả'), Tab(text: 'Chưa đọc')],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationList(context),
            const Center(child: Text('Không có thông báo chưa đọc')),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTimeHeader('Mới nhất'),
        _buildNotifItem('Yêu cầu đã hoàn thành', 'Yêu cầu "Xin bảng điểm hệ số 4" của bạn đã hoàn thành.', '10 phút trước', Icons.check_circle, AppColors.success),
        _buildNotifItem('Cần bổ sung', 'Giáo vụ yêu cầu bổ sung/cập nhật giấy tờ cho đơn "Xác nhận vay vốn sinh viên"', '2 giờ trước', Icons.info, AppColors.warning),
        const SizedBox(height: 16),
        _buildTimeHeader('Trước đó'),
        _buildNotifItem('Yêu cầu đã hoàn thành', 'Yêu cầu "Xin bảng điểm hệ số 4" của bạn đã hoàn thành.', '10 phút trước', Icons.check_circle, AppColors.success),
      ],
    );
  }

  Widget _buildTimeHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
    );
  }

  Widget _buildNotifItem(String title, String body, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
              ],
            ),
          )
        ],
      ),
    );
  }
}