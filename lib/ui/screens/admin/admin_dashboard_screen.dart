// lib/ui/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../../../core/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;

  // Dữ liệu Realtime
  int _totalStudents = 0;
  int _totalStaff = 0;
  int _totalCategories = 0;
  
  int _pendingCount = 0;
  int _processingCount = 0;
  int _completedCount = 0;
  int _rejectedCount = 0;

  // BIẾN MỚI CHO THẺ SYSTEM HEALTH
  int _dbPing = 0;
  int _todayActivities = 0;

  @override
  void initState() {
    super.initState();
    _fetchAdminMetrics();
  }

  Future<void> _fetchAdminMetrics() async {
    try {
      // 1. ĐO PING THẬT CỦA DATABASE SUPABASE
      final stopwatch = Stopwatch()..start();
      await Supabase.instance.client.from('request_categories').select('id').limit(1);
      stopwatch.stop();
      int currentPing = stopwatch.elapsedMilliseconds;

      // 2. Kéo thông số User
      final usersRes = await Supabase.instance.client.from('users').select('role');
      int students = 0; int staff = 0;
      for (var u in usersRes) {
        if (u['role'] == 'student') students++;
        if (u['role'] == 'staff') staff++;
      }

      // 3. Kéo tổng danh mục
      final catRes = await Supabase.instance.client.from('request_categories').select('id');
      
      // 4. Kéo toàn bộ Đơn để vẽ Biểu đồ tròn
      final reqRes = await Supabase.instance.client.from('requests').select('status');
      int pend = 0; int proc = 0; int comp = 0; int rej = 0;
      for(var r in reqRes) {
        final s = r['status']?.toString().toLowerCase() ?? '';
        if (s == 'pending') { pend++; }
        else if (s == 'processing') { proc++; }
        else if (s == 'rejected') { rej++; }
        else { comp++; }
      }

      // 5. ĐẾM SỐ HOẠT ĐỘNG TRONG NGÀY TỪ AUDIT LOGS
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      int activitiesCount = 0;
      try {
        final logsRes = await Supabase.instance.client.from('audit_logs').select('id').gte('created_at', startOfDay);
        activitiesCount = logsRes.length;
      } catch (_) {
        // Bỏ qua nếu bảng audit_logs chưa có
      }

      if (mounted) {
        setState(() {
          _totalStudents = students;
          _totalStaff = staff;
          _totalCategories = catRes.length;
          
          _pendingCount = pend;
          _processingCount = proc;
          _completedCount = comp;
          _rejectedCount = rej;
          
          _dbPing = currentPing;
          _todayActivities = activitiesCount;

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải Admin Dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));

    final totalReq = _pendingCount + _processingCount + _completedCount + _rejectedCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1100;

        Widget buildPieChartCard() {
          return Container(
            height: 380, width: isCompact ? double.infinity : null, padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.gray200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phân bổ Trạng thái Đơn từ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 24),
                Expanded(
                  child: totalReq == 0 
                    ? const Center(child: Text('Chưa có dữ liệu đơn từ', style: TextStyle(color: AppColors.gray500)))
                    : Flex(
                        direction: isCompact && constraints.maxWidth < 600 ? Axis.vertical : Axis.horizontal,
                        children: [
                          Expanded(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4, centerSpaceRadius: 50,
                                sections: [
                                  if (_completedCount > 0) PieChartSectionData(color: AppColors.success, value: _completedCount.toDouble(), title: '${(_completedCount/totalReq*100).toStringAsFixed(1)}%', radius: 60, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  if (_pendingCount > 0) PieChartSectionData(color: Colors.blue, value: _pendingCount.toDouble(), title: '${(_pendingCount/totalReq*100).toStringAsFixed(1)}%', radius: 60, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  if (_processingCount > 0) PieChartSectionData(color: AppColors.warning, value: _processingCount.toDouble(), title: '${(_processingCount/totalReq*100).toStringAsFixed(1)}%', radius: 60, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  if (_rejectedCount > 0) PieChartSectionData(color: AppColors.danger, value: _rejectedCount.toDouble(), title: '${(_rejectedCount/totalReq*100).toStringAsFixed(1)}%', radius: 60, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                ]
                              )
                            )
                          ),
                          if (!isCompact || constraints.maxWidth >= 600) const SizedBox(width: 24),
                          Expanded(
                            flex: isCompact && constraints.maxWidth < 600 ? 0 : 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegend(AppColors.success, 'Đã hoàn thành ($_completedCount)'), const SizedBox(height: 12),
                                _buildLegend(Colors.blue, 'Chờ tiếp nhận ($_pendingCount)'), const SizedBox(height: 12),
                                _buildLegend(AppColors.warning, 'Đang xử lý ($_processingCount)'), const SizedBox(height: 12),
                                _buildLegend(AppColors.danger, 'Bị từ chối ($_rejectedCount)'),
                              ],
                            ),
                          )
                        ],
                      ),
                )
              ],
            ),
          );
        }

        // ─── THẺ SỨC KHỎE HỆ THỐNG MỚI CHẠY BẰNG DATA THẬT ───
        Widget buildServerCard() {
          return Container(
            height: 380, width: isCompact ? double.infinity : null, padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.gray200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.monitor_heart_rounded, color: Color(0xFF1E3A8A)), SizedBox(width: 8), Text('Sức khỏe Hệ thống', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900))]),
                const SizedBox(height: 24),
                _buildServerMetric('Độ trễ Database (Ping)', '$_dbPing ms', _dbPing < 200 ? Colors.green : AppColors.warning),
                const Divider(height: 30),
                _buildServerMetric('Đơn đang tồn đọng', '$_pendingCount đơn', _pendingCount > 0 ? AppColors.warning : AppColors.gray500),
                const Divider(height: 30),
                _buildServerMetric('Lượt hoạt động hôm nay', '$_todayActivities thao tác', Colors.blue),
                const Spacer(),
                SizedBox(
                  width: double.infinity, height: 48, 
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _fetchAdminMetrics();
                    }, 
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18), 
                    label: const Text('Làm mới dữ liệu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
                  )
                )
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng quan Nền tảng', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gray900)),
              const SizedBox(height: 8),
              const Text('Thống kê dữ liệu người dùng và hiệu suất xử lý hệ thống theo thời gian thực.', style: TextStyle(fontSize: 15, color: AppColors.gray500)),
              const SizedBox(height: 32),

              if (isCompact) ...[
                Row(children: [Expanded(child: _AdminStatCard(title: 'Tổng Sinh viên', value: '$_totalStudents', icon: Icons.school_rounded, color: Colors.blue)), const SizedBox(width: 16), Expanded(child: _AdminStatCard(title: 'Tài khoản Cán bộ', value: '$_totalStaff', icon: Icons.manage_accounts_rounded, color: Colors.purple))]),
                const SizedBox(height: 16),
                Row(children: [Expanded(child: _AdminStatCard(title: 'Danh mục Đơn từ', value: '$_totalCategories', icon: Icons.folder_copy_rounded, color: Colors.orange)), const SizedBox(width: 16), Expanded(child: _AdminStatCard(title: 'Tổng Đơn hệ thống', value: '$totalReq', icon: Icons.receipt_long_rounded, color: Colors.teal))]),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: _AdminStatCard(title: 'Tổng Sinh viên', value: '$_totalStudents', icon: Icons.school_rounded, color: Colors.blue)), const SizedBox(width: 24),
                    Expanded(child: _AdminStatCard(title: 'Tài khoản Cán bộ', value: '$_totalStaff', icon: Icons.manage_accounts_rounded, color: Colors.purple)), const SizedBox(width: 24),
                    Expanded(child: _AdminStatCard(title: 'Danh mục Đơn từ', value: '$_totalCategories', icon: Icons.folder_copy_rounded, color: Colors.orange)), const SizedBox(width: 24),
                    Expanded(child: _AdminStatCard(title: 'Tổng Đơn hệ thống', value: '$totalReq', icon: Icons.receipt_long_rounded, color: Colors.teal)),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              if (isCompact) ...[
                buildPieChartCard(),
                const SizedBox(height: 24),
                buildServerCard(),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: buildPieChartCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 3, child: buildServerCard()),
                  ],
                )
              ]
            ],
          ),
        );
      }
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900), maxLines: 1, overflow: TextOverflow.ellipsis))]);
  }

  Widget _buildServerMetric(String label, String value, Color valueColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: AppColors.gray500, fontWeight: FontWeight.w500)), Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold))]);
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title; final String value; final IconData icon; final Color color;
  const _AdminStatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gray200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: AppColors.gray500, fontWeight: FontWeight.w600)), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22))]),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.gray900)),
        ],
      ),
    );
  }
}