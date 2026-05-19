// lib/ui/screens/staff/teacher_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1100;
    final isTablet = screenWidth > 768 && screenWidth <= 1100;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER CO ANIMATION NÚT BẤM ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng quan Thống kê', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gray900, letterSpacing: -0.5)),
                    SizedBox(height: 6),
                    Text('Theo dõi tiến độ xử lý đơn từ sinh viên HDPE', style: TextStyle(fontSize: 15, color: AppColors.gray500, fontWeight: FontWeight.w500)),
                  ],
                ),
                _HoverButton(
                  text: 'Xuất báo cáo',
                  icon: Icons.download_rounded,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 28),

            if (isDesktop)
              Row(
                children: [
                  Expanded(child: _HoverStatCard(title: 'Tổng đơn tiếp nhận', value: '1,245', trend: '+12.5%', icon: Icons.insert_chart_rounded, color: AppColors.primarySV)),
                  const SizedBox(width: 20),
                  Expanded(child: _HoverStatCard(title: 'Đang chờ xử lý', value: '48', trend: '-2.4%', icon: Icons.timer_rounded, color: AppColors.warning)),
                  const SizedBox(width: 20),
                  Expanded(child: _HoverStatCard(title: 'Đã hoàn thành', value: '1,102', trend: '+18.2%', icon: Icons.check_circle_rounded, color: AppColors.success)),
                  const SizedBox(width: 20),
                  Expanded(child: _HoverStatCard(title: 'Đã từ chối/Hủy', value: '95', trend: '+1.1%', icon: Icons.cancel_rounded, color: AppColors.danger)),
                ],
              )
            else if (isTablet)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _HoverStatCard(title: 'Tổng đơn', value: '1,245', trend: '+12.5%', icon: Icons.insert_chart_rounded, color: AppColors.primarySV)),
                      const SizedBox(width: 20),
                      Expanded(child: _HoverStatCard(title: 'Đang chờ', value: '48', trend: '-2.4%', icon: Icons.timer_rounded, color: AppColors.warning)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _HoverStatCard(title: 'Hoàn thành', value: '1,102', trend: '+18.2%', icon: Icons.check_circle_rounded, color: AppColors.success)),
                      const SizedBox(width: 20),
                      Expanded(child: _HoverStatCard(title: 'Từ chối/Hủy', value: '95', trend: '+1.1%', icon: Icons.cancel_rounded, color: AppColors.danger)),
                    ],
                  ),
                ],
              )
            else
              Column(
                children: [
                  _HoverStatCard(title: 'Tổng đơn tiếp nhận', value: '1,245', trend: '+12.5%', icon: Icons.insert_chart_rounded, color: AppColors.primarySV),
                  const SizedBox(height: 16),
                  _HoverStatCard(title: 'Đang chờ xử lý', value: '48', trend: '-2.4%', icon: Icons.timer_rounded, color: AppColors.warning),
                  const SizedBox(height: 16),
                  _HoverStatCard(title: 'Đã hoàn thành', value: '1,102', trend: '+18.2%', icon: Icons.check_circle_rounded, color: AppColors.success),
                  const SizedBox(height: 16),
                  _HoverStatCard(title: 'Đã từ chối/Hủy', value: '95', trend: '+1.1%', icon: Icons.cancel_rounded, color: AppColors.danger),
                ],
              ),

            const SizedBox(height: 28),

            // ─── KHU VỰC BIỂU ĐỒ VÀ HOẠT ĐỘNG GẦN ĐÂY ───
            Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khung Biểu đồ
                Expanded(
                  flex: isDesktop ? 2 : 0,
                  child: _HoverContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lưu lượng Yêu cầu theo tháng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                        const SizedBox(height: 6),
                        const Text('Thống kê số lượng đơn tiếp nhận và hoàn thành', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                        const SizedBox(height: 32),
                        Container(
                          height: 320,
                          width: double.infinity,
                          decoration: BoxDecoration(color: AppColors.gray100.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gray200, width: 1.5)),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_graph_rounded, size: 72, color: AppColors.gray200),
                              SizedBox(height: 16),
                              Text('Khu vực hiển thị Biểu đồ (Sử dụng fl_chart)', style: TextStyle(color: AppColors.gray500, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isDesktop) const SizedBox(width: 24),
                if (!isDesktop) const SizedBox(height: 24),
                
                // Khung Hoạt động gần đây
                Expanded(
                  flex: isDesktop ? 1 : 0,
                  child: _HoverContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Hoạt động gần đây', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.more_horiz_rounded, size: 20, color: AppColors.gray500)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _HoverActivityItem(title: 'Đã duyệt đơn xin bảng điểm', subtitle: 'SV: Lê Nhật Thiện (2001234567)', time: '10 phút trước', color: AppColors.success),
                        _HoverActivityItem(title: 'Đơn bảo lưu mới', subtitle: 'SV: Võ Xuân Trường (2009876543)', time: '1 giờ trước', color: AppColors.warning),
                        _HoverActivityItem(title: 'Từ chối đơn hủy môn', subtitle: 'SV: Trần Tiến Hoài Nam (2001122334)', time: '2 giờ trước', color: AppColors.danger),
                        _HoverActivityItem(title: 'Cập nhật danh mục', subtitle: 'Admin: Hệ thống', time: 'Hôm qua', color: AppColors.primarySV),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── THẺ THỐNG KÊ (Hover Scale & Shadow) ───
class _HoverStatCard extends StatefulWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;

  const _HoverStatCard({required this.title, required this.value, required this.trend, required this.icon, required this.color});

  @override
  State<_HoverStatCard> createState() => _HoverStatCardState();
}

class _HoverStatCardState extends State<_HoverStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.trend.startsWith('+');
    final trendColor = isPositive ? AppColors.success : AppColors.danger;
    final trendIcon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0), 
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isHovered ? widget.color.withValues(alpha: 0.3) : AppColors.gray200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? widget.color.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03),
              blurRadius: _isHovered ? 24 : 10,
              offset: Offset(0, _isHovered ? 12 : 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(widget.title, style: const TextStyle(color: AppColors.gray500, fontSize: 14.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: widget.color.withValues(alpha: _isHovered ? 0.15 : 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(widget.value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.gray900, letterSpacing: -1)),
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: trendColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, size: 14, color: trendColor),
                      const SizedBox(width: 4),
                      Text(widget.trend, style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGET ANIMATION: KHUNG CONTAINER CHUNG ───
class _HoverContainer extends StatefulWidget {
  final Widget child;
  const _HoverContainer({required this.child});

  @override
  State<_HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<_HoverContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gray200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.02),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            )
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

// ─── WIDGET ANIMATION: ITEM HOẠT ĐỘNG GẦN ĐÂY ───
class _HoverActivityItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _HoverActivityItem({required this.title, required this.subtitle, required this.time, required this.color});

  @override
  State<_HoverActivityItem> createState() => _HoverActivityItemState();
}

class _HoverActivityItemState extends State<_HoverActivityItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14), // Tăng nhẹ padding cho khoảng rê rộng hơn
          transform: Matrix4.translationValues(_isHovered ? 6 : 0, 0, 0), 
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.gray100.withValues(alpha: 0.7) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: widget.color, 
                  shape: BoxShape.circle, 
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4), 
                      blurRadius: _isHovered ? 10 : 6, 
                      spreadRadius: _isHovered ? 4 : 1
                    )
                  ]
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: _isHovered ? const Color(0xFF4F46E5) : AppColors.gray900)),
                    const SizedBox(height: 4),
                    Text(widget.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
                  ],
                ),
              ),
              Text(widget.time, style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
}
}

// ─── WIDGET ANIMATION: NÚT BẤM HEADER ───
class _HoverButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _HoverButton({required this.text, required this.icon, required this.onPressed});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF4F46E5) : AppColors.primarySV, 
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primarySV.withValues(alpha: _isHovered ? 0.5 : 0.3),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 6 : 2),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(widget.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}