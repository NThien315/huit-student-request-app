import 'package:flutter/material.dart';
import '../admin_web_data.dart';
import '../admin_web_models.dart';
import '../widgets/admin_common.dart';

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = AdminMockData.getStats();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Tổng quan Thống kê',
                  subtitle: 'Theo dõi tiến độ xử lý đơn từ sinh viên HDPE',
                ),
              ),
              BlueButton(
                text: 'Xuất báo cáo',
                icon: Icons.download_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xuất báo cáo demo')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: List.generate(stats.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == stats.length - 1 ? 0 : 20),
                  child: _DashboardStatCard(data: stats[index], activeBorder: index == 1),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: WhiteBox(
                  height: 420,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lưu lượng Yêu cầu theo tháng',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminColors.text),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thống kê số lượng đơn tiếp nhận theo 6 tháng gần nhất',
                        style: TextStyle(color: AdminColors.muted),
                      ),
                      const SizedBox(height: 28),
                      Expanded(child: CustomPaint(painter: LineChartPainter(), child: Container())),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(child: _RecentActivityPanel()),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final AdminStat data;
  final bool activeBorder;

  const _DashboardStatCard({
    required this.data,
    this.activeBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activeBorder ? const Color(0xffffe0a3) : AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data.title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff475569))),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: data.color.withOpacity(.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(data.icon, color: data.color),
              ),
            ],
          ),
          const Spacer(),
          Text('${data.value}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xffffeeee), borderRadius: BorderRadius.circular(20)),
            child: Text(
              data.percent,
              style: const TextStyle(color: AdminColors.red, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  const _RecentActivityPanel();

  @override
  Widget build(BuildContext context) {
    return WhiteBox(
      height: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hoạt động gần đây',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AdminColors.text),
                ),
              ),
              Icon(Icons.more_horiz_rounded),
            ],
          ),
          SizedBox(height: 24),
          _ActivityItem(color: AdminColors.green, title: 'Đã duyệt đơn xin bảng điểm', subtitle: 'SV: Lê Nhật Thiện (2001234567)', time: '10 phút trước'),
          _ActivityItem(color: AdminColors.orange, title: 'Đơn bảo lưu mới', subtitle: 'SV: Võ Xuân Trường (2009876543)', time: '1 giờ trước'),
          _ActivityItem(color: AdminColors.red, title: 'Từ chối đơn hủy môn', subtitle: 'SV: Trần Tiến Hoài Nam (2001122334)', time: '2 giờ trước'),
          _ActivityItem(color: AdminColors.blue, title: 'Cập nhật danh mục', subtitle: 'Admin: Hệ thống', time: 'Hôm qua'),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 12, width: 12, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AdminColors.text)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: AdminColors.muted)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: AdminColors.muted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
