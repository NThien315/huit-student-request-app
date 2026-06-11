import 'package:flutter/material.dart';
import 'package:huit_student_request_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:huit_student_request_app/ui/screens/student/create_request_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../models/request_model.dart';
import '../../../services/db_service.dart';
import '../../../services/huit_scraper_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true; 

  String _userName = "Sinh viên";
  String _mssv = "Đang cập nhật...";
  String _avatarUrl = "";
  List<Map<String, dynamic>> _categories = [];
  bool _hasError = false;

  // ─── HÀM GÁN MÀU SẮC PASTEL & GLOW EFFECT CHUẨN XÁC ───
  Map<String, dynamic> _getDynamicStyle(String catName) {
    final name = catName.toLowerCase();
    if (name.contains('học phí') || name.contains('bảo lưu')) return {'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFFFCE7F3), 'iconColor': const Color(0xFFEC4899)};
    if (name.contains('điểm') || name.contains('phúc khảo')) return {'icon': Icons.assignment_turned_in_rounded, 'color': const Color(0xFFDCFCE7), 'iconColor': const Color(0xFF10B981)};
    if (name.contains('sinh viên') || name.contains('chứng nhận')) return {'icon': Icons.badge_rounded, 'color': const Color(0xFFE0E7FF), 'iconColor': const Color(0xFF3B82F6)};
    if (name.contains('thôi học') || name.contains('hủy') || name.contains('rút')) return {'icon': Icons.disabled_by_default_rounded, 'color': const Color(0xFFFEE2E2), 'iconColor': const Color(0xFFEF4444)};
    if (name.contains('thi') || name.contains('lịch')) return {'icon': Icons.event_busy_rounded, 'color': const Color(0xFFFEF3C7), 'iconColor': const Color(0xFFF59E0B)};
    if (name.contains('học bổng') || name.contains('vượt khó')) return {'icon': Icons.card_membership_rounded, 'color': const Color(0xFFFAE8FF), 'iconColor': const Color(0xFFD946EF)};
    return {'icon': Icons.apps_rounded, 'color': const Color(0xFFF3F4F6), 'iconColor': const Color(0xFF6B7280)};
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userName = prefs.getString('saved_user_name') ?? "Sinh viên";
          _mssv = prefs.getString('saved_user_mssv') ?? "";
          _hasError = false;
        });
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client.from('users').select('name, studentId, avatar_url').eq('uid', user.id).maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _userName = data['name'] ?? "Sinh viên HDPE";
          _mssv = data['studentId'] ?? "";
          _avatarUrl = data['avatar_url'] ?? ""; // Lưu link ảnh
        });
        await prefs.setString('saved_user_name', _userName);
        await prefs.setString('saved_user_mssv', _mssv);
      }

      // KÉO DANH MỤC THỰC TẾ
      final catData = await Supabase.instance.client.from('request_categories').select().eq('isActive', true).order('name');
      if (mounted) setState(() => _categories = List<Map<String, dynamic>>.from(catData));
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = AuthService().currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, 
      child: Scaffold(
        backgroundColor: Colors.white, 
        body: SafeArea(
          bottom: false, 
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primarySV,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  
                  // 1. Thẻ Welcome
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primarySV.withValues(alpha: 0.15), AppColors.lightSV.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.primarySV.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.lightBlue.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: const Text('Xin chào', style: TextStyle(fontSize: 14, color: AppColors.white, fontWeight: FontWeight.w600))),
                                const SizedBox(height: 4),
                                Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primarySV)),
                                Text("MSSV: $_mssv", style: const TextStyle(color: AppColors.gray500, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle, 
                              boxShadow: [BoxShadow(color: AppColors.primarySV.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                              image: _avatarUrl.isNotEmpty ? DecorationImage(image: NetworkImage(_avatarUrl), fit: BoxFit.cover) : null,
                            ),
                            child: _avatarUrl.isEmpty ? const Icon(Icons.person_rounded, color: AppColors.primarySV, size: 35) : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Thống kê nhanh
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Thống kê nhanh', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900))),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      // Thay đổi luồng stream trực tiếp từ bảng 'requests' để lấy data thô real-time
                      stream: Supabase.instance.client
                          .from('requests')
                          .stream(primaryKey: ['id'])
                          .eq('studentUid', user?.id ?? '')
                          .order('createdAt', ascending: false)
                          .asBroadcastStream(),
                      builder: (context, snapshot) {
                        int pending = 0;
                        int processing = 0;
                        int completed = 0;
                        int rejected = 0;

                        if (snapshot.hasData && snapshot.data != null) {
                          final list = snapshot.data!;
                          for (var req in list) {
                            // Đọc trực tiếp trường 'status' dạng String nguyên bản từ database
                            final String statusStr = (req['status'] ?? 'pending').toString().toLowerCase();
                            
                            if (statusStr == 'pending') {
                              pending++;
                            } else if (statusStr == 'processing') {
                              processing++;
                            } else if (statusStr == 'approved' || statusStr == 'completed') {
                              completed++;
                            } else if (statusStr == 'rejected') {
                              rejected++;
                            }
                          }
                        }
                        
                        return Column(
                          children: [
                            Row(children: [_buildStatCard('Chờ tiếp nhận', pending, AppColors.lightSV, AppColors.primarySV), const SizedBox(width: 12), _buildStatCard('Đang xử lý', processing, AppColors.warningLight, AppColors.warning)]),
                            const SizedBox(height: 12),
                            Row(children: [_buildStatCard('Hoàn thành', completed, AppColors.successLight, AppColors.success), const SizedBox(width: 12), _buildStatCard('Đã huỷ', rejected, AppColors.dangerLight, AppColors.danger)]),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 3. Tính năng chính (Grid View Lọc Động)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Tính năng chính', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900))),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    // DÙNG ANIMATED SIZE ĐỂ TỰ CO GIÃN THAY VÌ FIX CỨNG CHIỀU CAO
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _categories.isEmpty 
                        ? const Center(child: Text('Chưa có danh mục tính năng...'))
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 16, childAspectRatio: 0.82),
                            // Tính toán số lượng item hiển thị
                            itemCount: _isExpanded ? _categories.length + 1 : (_categories.length > 5 ? 6 : _categories.length),
                            itemBuilder: (context, index) {
                              if ((!_isExpanded && index == 5) || (_isExpanded && index == _categories.length)) {
                                return _buildExpandButton();
                              }
                              
                              final cat = _categories[index];
                              final style = _getDynamicStyle(cat['name']);
                              final Color baseColor = style['iconColor'] as Color;
                              final Color pastelColor = style['color'] as Color;

                              return InkWell(
                                onTap: () {
                                  // ĐIỀU HƯỚNG TỰ ĐỘNG CHỌN ĐƠN
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => CreateRequestScreen(initialCategory: cat)));
                                },
                                splashColor: Colors.transparent, highlightColor: Colors.transparent,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: pastelColor, borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: baseColor.withValues(alpha: 0.1), width: 1),
                                        // FIX HIỆU ỨNG GLOW PHÁT SÁNG THEO MÀU ICON
                                        boxShadow: [BoxShadow(color: baseColor.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6), spreadRadius: -1)],
                                      ),
                                      child: Icon(style['icon'] as IconData, color: baseColor, size: 30),
                                    ),
                                    const SizedBox(height: 10),
                                    Expanded(child: Text(cat['name'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray900, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              );
                            },
                          ),
                    ),
                  ),

                  // 4. Bảng tin trường HUIT
                  const SchoolNewsSection(),

                  if (_hasError)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1))),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 30), const SizedBox(height: 8),
                            const Text("Không thể cập nhật dữ liệu mới nhất. Vui lòng kiểm tra kết nối mạng.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.gray500)),
                            TextButton(onPressed: _loadData, child: const Text("Thử lại", style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 120), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      splashColor: Colors.transparent, highlightColor: Colors.transparent,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray100, borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.grid_view_rounded, color: AppColors.gray500, size: 30),
          ),
          const SizedBox(height: 10),
          Text(_isExpanded ? 'Thu gọn' : 'Xem thêm', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray900)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color bgColor, Color mainColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gray100),
          boxShadow: [BoxShadow(color: mainColor.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(width: 35, height: 35, alignment: Alignment.center, decoration: BoxDecoration(color: mainColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: mainColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]), child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class SchoolNewsSection extends StatelessWidget {
  const SchoolNewsSection({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw 'Không thể mở liên kết $url';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bảng tin nhà trường', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              TextButton(onPressed: () => _launchURL('https://sinhvien.huit.edu.vn/sinh-vien/dm-tin-tuc/thong-tin-chung-095310.html'), child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primarySV)))
            ],
          ),
        ),
        FutureBuilder<List<Map<String, String>>>(
          future: HuitScraperService.fetchAnnouncements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Column(children: List.generate(3, (index) => Container(margin: const EdgeInsets.only(bottom: 16), height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))))));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Không có tin tức mới'));

            return ListView.builder(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snapshot.data!.length, padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: AppColors.gray100)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16), onTap: () => _launchURL(item['link'] ?? ''),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.lightSV, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.campaign_rounded, color: AppColors.primarySV, size: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900, height: 1.4)),
                                const SizedBox(height: 8),
                                Row(children: [const Icon(Icons.access_time, size: 14, color: AppColors.gray500), const SizedBox(width: 4), Text(item['date'] ?? 'Tin mới', style: const TextStyle(fontSize: 12, color: AppColors.gray500)), const Spacer(), const Text('Xem chi tiết', style: TextStyle(fontSize: 12, color: AppColors.primarySV, fontWeight: FontWeight.w500))]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}