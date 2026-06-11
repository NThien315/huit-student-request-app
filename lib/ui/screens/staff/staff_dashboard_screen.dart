// lib/ui/screens/staff/staff_dashboard_screen.dart
import 'dart:convert';
import 'package:huit_student_request_app/services/web_exporter_stub.dart'
    if (dart.library.html) 'package:huit_student_request_app/services/web_exporter_web.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../core/theme.dart';
import '../../widgets/glass_toast.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoadingStats = true;

  int _totalRequests = 0;
  int _pendingRequests = 0;
  int _processingRequests = 0;
  int _completedRequests = 0;

  List<Map<String, dynamic>> _urgentRequests = [];
  List<Map<String, dynamic>> _recentActivities = [];
  List<FlSpot> _chartSpots = [];

  late final AnimationController _animController; 

  String _chartFilter = 'month'; 
  Map<int, int> _monthlyData = {};
  Map<int, int> _dailyData = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fetchDashboardStats();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final response = await Supabase.instance.client.from('requests').select('status, createdAt, categoryName, studentName, id').order('createdAt', ascending: false);
      
      int total = response.length;
      int pending = 0, processing = 0, completed = 0;
      
      final now = DateTime.now();
      Map<int, int> monthlyCounts = {for (var i = 0; i < 6; i++) now.month - i <= 0 ? (now.month - i + 12) : (now.month - i): 0};
      Map<int, int> dailyCounts = {for (var i = 0; i < 7; i++) now.subtract(Duration(days: i)).day: 0};

      List<Map<String, dynamic>> urgent = [];
      List<Map<String, dynamic>> activities = [];

      for (var req in response) {
        final status = req['status']?.toString().toLowerCase() ?? '';
        if (status == 'pending') { pending++; urgent.add(req); }
        else if (status == 'processing') { processing++; }
        else if (status == 'approved' || status == 'completed') { completed++; }

        if (activities.length < 5) activities.add(req);

        if (req['createdAt'] != null) {
          try {
            final date = DateTime.parse(req['createdAt']).toLocal();
            if (monthlyCounts.containsKey(date.month)) monthlyCounts[date.month] = monthlyCounts[date.month]! + 1;
            if (dailyCounts.containsKey(date.day)) dailyCounts[date.day] = dailyCounts[date.day]! + 1;
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _totalRequests = total; _pendingRequests = pending; _processingRequests = processing; _completedRequests = completed;
          _monthlyData = monthlyCounts; _dailyData = dailyCounts;
          _recentActivities = activities;
          _urgentRequests = urgent.reversed.take(5).toList();
          _isLoadingStats = false;
        });
        _updateChartSpots(); 
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  void _updateChartSpots() {
    List<FlSpot> spots = [];
    int x = 0;
    final now = DateTime.now();
    
    if (_chartFilter == 'month') {
      for (var i = 5; i >= 0; i--) {
        int m = now.month - i <= 0 ? (now.month - i + 12) : (now.month - i);
        spots.add(FlSpot(x.toDouble(), (_monthlyData[m] ?? 0).toDouble()));
        x++;
      }
    } else {
      for (var i = 6; i >= 0; i--) {
        int d = now.subtract(Duration(days: i)).day;
        spots.add(FlSpot(x.toDouble(), (_dailyData[d] ?? 0).toDouble()));
        x++;
      }
    }
    setState(() => _chartSpots = spots);
  }

  void _exportCSV() {
    if (_recentActivities.isEmpty) {
      GlassToast.show(context, 'Không có dữ liệu để xuất!', isError: true);
      return;
    }
    
    String csv = "Mã Đơn,Tên SV,Loại Đơn,Trạng thái\n";
    for(var req in _recentActivities) {
      csv += "${req['id']},${req['studentName']},${req['categoryName']},${req['status']}\n";
    }

    // GỌI HÀM BIÊN DỊCH
    WebExporter.downloadCSVWeb(csv, "Bao_Cao_Giao_Vu_HDPE", context);

    GlassToast.show(context, 'Đang trích xuất báo cáo...');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: _isLoadingStats 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primarySV))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FadeInSlide(
                  index: 0, controller: _animController,
                  // FIX UI BẰNG WRAP CHO HEADER
                  child: Wrap(
                    spacing: 16, runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tổng quan Thống kê', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                          SizedBox(height: 6),
                          Text('Theo dõi tiến độ xử lý đơn từ sinh viên', style: TextStyle(color: AppColors.gray500, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      _HoverButton(text: 'Xuất CSV', icon: Icons.download_rounded, onPressed: _exportCSV),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                _FadeInSlide(
                  index: 1, controller: _animController,
                  // FIX UI BẰNG WRAP CHO 4 THẺ THỐNG KÊ
                  child: Wrap(
                    spacing: 20, runSpacing: 20,
                    children: [
                      SizedBox(width: screenWidth < 700 ? double.infinity : 280, child: _HoverStatCard(title: 'Tổng yêu cầu', value: '$_totalRequests', icon: Icons.insert_chart_rounded, color: AppColors.primarySV)),
                      SizedBox(width: screenWidth < 700 ? double.infinity : 280, child: _HoverStatCard(title: 'Chờ duyệt', value: '$_pendingRequests', icon: Icons.timer_rounded, color: AppColors.danger)),
                      SizedBox(width: screenWidth < 700 ? double.infinity : 280, child: _HoverStatCard(title: 'Đang xử lý', value: '$_processingRequests', icon: Icons.cached_rounded, color: AppColors.warning)),
                      SizedBox(width: screenWidth < 700 ? double.infinity : 280, child: _HoverStatCard(title: 'Hoàn thành', value: '$_completedRequests', icon: Icons.check_circle_rounded, color: AppColors.success)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                _FadeInSlide(
                  index: 2, controller: _animController,
                  // FIX UI BẰNG WRAP CHO 2 KHỐI LỚN
                  child: Wrap(
                    spacing: 24, runSpacing: 24,
                    children: [
                      // Khối Biểu đồ
                      Container(
                        width: screenWidth < 1200 ? double.infinity : 700,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gray200, width: 1.5)),
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Lưu lượng Yêu cầu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                Container(
                                  decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      InkWell(onTap: () { setState(() => _chartFilter = 'day'); _updateChartSpots(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _chartFilter == 'day' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: _chartFilter == 'day' ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : []), child: Text('7 Ngày', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _chartFilter == 'day' ? AppColors.primarySV : AppColors.gray500)))),
                                      InkWell(onTap: () { setState(() => _chartFilter = 'month'); _updateChartSpots(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _chartFilter == 'month' ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: _chartFilter == 'month' ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : []), child: Text('6 Tháng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _chartFilter == 'month' ? AppColors.primarySV : AppColors.gray500)))),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(height: 320, width: double.infinity, child: _buildLineChart()), 
                          ],
                        ),
                      ),
                      
                      // Khối Hoạt động
                      Container(
                        width: screenWidth < 1200 ? double.infinity : 400,
                        child: Column(
                          children: [
                            _HoverContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20), SizedBox(width: 8), Text('Cần xử lý gấp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.danger))]),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)), child: Text('${_urgentRequests.length} đơn', style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_urgentRequests.isEmpty) const Text('Tuyệt vời! Không có đơn nào trễ hạn.', style: TextStyle(color: AppColors.gray500))
                                  else ..._urgentRequests.map((req) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Container(width: 4, height: 40, decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 12),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(req['categoryName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), Text('${req['studentName']} - ${req['createdAt'].toString().substring(0, 10)}', style: const TextStyle(fontSize: 12, color: AppColors.gray500))])),
                                        TextButton(onPressed: () { GlassToast.show(context, 'Mở tab Quản lý yêu cầu để xử lý yêu cầu ${req['id'].toString().substring(0,6)}...'); }, child: const Text('Xử lý', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))
                                      ],
                                    ),
                                  ))
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _HoverContainer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Hoạt động gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_horiz_rounded, color: AppColors.gray500),
                                        onSelected: (value) { if (value == 'refresh') _fetchDashboardStats(); },
                                        itemBuilder: (BuildContext context) => [const PopupMenuItem(value: 'refresh', child: Row(children: [Icon(Icons.refresh, size: 18), SizedBox(width: 8), Text('Làm mới')]))],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_recentActivities.isEmpty) const Text('Chưa có hoạt động', style: TextStyle(color: AppColors.gray500))
                                  else ..._recentActivities.map((req) {
                                    Color c = AppColors.primarySV;
                                    String action = 'Nộp đơn mới';
                                    if (req['status'] == 'approved') { c = AppColors.success; action = 'Đã duyệt'; }
                                    if (req['status'] == 'rejected') { c = AppColors.danger; action = 'Từ chối'; }
                                    return _HoverActivityItem(title: '$action: ${req['categoryName']}', subtitle: 'SV: ${req['studentName']}', time: 'Gần đây', color: c);
                                  })
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        minY: 0, 
        clipData: const FlClipData.all(),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.gray200, strokeWidth: 1, dashArray: [5, 5])),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (value, meta) {
            final now = DateTime.now(); 
            if (_chartFilter == 'month') {
              int m = now.month - 5 + value.toInt(); if(m <= 0) m += 12;
              return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Tháng $m', style: const TextStyle(color: AppColors.gray500, fontSize: 12, fontWeight: FontWeight.bold)));
            } else {
              int d = now.subtract(Duration(days: 6 - value.toInt())).day;
              return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Ng $d', style: const TextStyle(color: AppColors.gray500, fontSize: 12, fontWeight: FontWeight.bold)));
            }
          })),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            preventCurveOverShooting: true, 
            spots: _chartSpots.isEmpty ? const [FlSpot(0, 0)] : _chartSpots,
            isCurved: true, color: AppColors.primarySV, barWidth: 4, isStrokeCapRound: true, dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primarySV.withValues(alpha: 0.25), AppColors.primarySV.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          ),
        ],
      ),
    );
  }
}

class _FadeInSlide extends StatelessWidget {
  final int index; final AnimationController controller; final Widget child;
  const _FadeInSlide({required this.index, required this.controller, required this.child});
  @override
  Widget build(BuildContext context) {
    final delay = (index * 0.2).clamp(0.0, 1.0);
    final animation = CurvedAnimation(parent: controller, curve: Interval(delay, 1.0, curve: Curves.easeOutCubic));
    return AnimatedBuilder(animation: animation, builder: (context, child) => Transform.translate(offset: Offset(0, 30 * (1 - animation.value)), child: Opacity(opacity: animation.value, child: child)), child: child);
  }
}

class _HoverStatCard extends StatefulWidget {
  final String title; final String value; final IconData icon; final Color color;
  const _HoverStatCard({required this.title, required this.value, required this.icon, required this.color});
  @override
  State<_HoverStatCard> createState() => _HoverStatCardState();
}
class _HoverStatCardState extends State<_HoverStatCard> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), padding: const EdgeInsets.all(24), transform: Matrix4.translationValues(0, _isHovered ? -6 : 0, 0), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _isHovered ? widget.color.withValues(alpha: 0.3) : AppColors.gray200), boxShadow: [BoxShadow(color: _isHovered ? widget.color.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 12))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(widget.title, style: const TextStyle(color: AppColors.gray500, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)), AnimatedContainer(duration: const Duration(milliseconds: 250), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(widget.icon, color: widget.color, size: 22))]),
            const SizedBox(height: 16),
            Text(widget.value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.gray900)),
          ],
        ),
      ),
    );
  }
}

class _HoverContainer extends StatefulWidget {
  final Widget child; const _HoverContainer({required this.child});
  @override
  State<_HoverContainer> createState() => _HoverContainerState();
}
class _HoverContainerState extends State<_HoverContainer> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gray200, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _isHovered ? 0.06 : 0.02), blurRadius: 20, offset: const Offset(0, 8))]), child: widget.child),
    );
  }
}

class _HoverActivityItem extends StatefulWidget {
  final String title; final String subtitle; final String time; final Color color;
  const _HoverActivityItem({required this.title, required this.subtitle, required this.time, required this.color});
  @override
  State<_HoverActivityItem> createState() => _HoverActivityItemState();
}
class _HoverActivityItemState extends State<_HoverActivityItem> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(10), transform: Matrix4.translationValues(_isHovered ? 6 : 0, 0, 0), 
          decoration: BoxDecoration(color: _isHovered ? AppColors.primarySV.withValues(alpha: 0.05) : Colors.transparent, borderRadius: BorderRadius.circular(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(margin: const EdgeInsets.only(top: 4), width: 10, height: 10, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isHovered ? AppColors.primarySV : AppColors.gray900), maxLines: 1, overflow: TextOverflow.ellipsis), Text(widget.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray500), maxLines: 1, overflow: TextOverflow.ellipsis)])),
              Text(widget.time, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  final String text; final IconData icon; final VoidCallback onPressed;
  const _HoverButton({required this.text, required this.icon, required this.onPressed});
  @override
  State<_HoverButton> createState() => _HoverButtonState();
}
class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), 
          transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0), 
          
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
          
          decoration: BoxDecoration(color: _isHovered ? const Color(0xFF4F46E5) : AppColors.primarySV, borderRadius: BorderRadius.circular(12)), 
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: Colors.white), 
              const SizedBox(width: 8), 
              Text(widget.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))
            ]
          )
        )
      ),
    );
  }
}