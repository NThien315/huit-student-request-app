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

  // 1. Khai báo biến trạng thái ở cấp độ Class
  String _userName = "Sinh viên";
  String _mssv = "Đang cập nhật...";

  @override
  void initState() {
    super.initState();
    // 2. Gọi hàm tải dữ liệu ngay khi khởi tạo màn hình
    _loadData();
  }

  // 3. Đưa hàm xử lý logic ra khỏi hàm build
  bool _hasError = false;
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Lấy dữ liệu đã lưu trong máy ra hiển thị ngay lập tức
      if (mounted) {
        setState(() {
          _userName = prefs.getString('saved_user_name') ?? "Sinh viên";
          _mssv = prefs.getString('saved_user_mssv') ?? "";
          _hasError = false;
        });
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Gọi API Supabase để lấy dữ liệu mới nhất
      final data = await Supabase.instance.client
          .from('users')
          .select('name, studentId')
          .eq('uid', user.id)
          .maybeSingle();

      if (mounted && data != null) {
        setState(() {
          _userName = data['name'] ?? "Sinh viên HDPE";
          _mssv = data['studentId'] ?? "";
        });

        // Lưu lại dữ liệu mới nhất vào máy cho lần mở app sau
        await prefs.setString('saved_user_name', _userName);
        await prefs.setString('saved_user_mssv', _mssv);
      }
    } catch (e) {
      debugPrint("Lỗi load data: $e");
      if (mounted) {
        setState(() => _hasError = true);
      }
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
    
    // Khai báo lại biến user để StreamBuilder sử dụng
    final user = AuthService().currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, 
      child: Scaffold(
      // Để nền trong suốt để thấy được phía sau NavBar của MainNavigation
      backgroundColor: Colors.white, 
      body: Container(
        color: AppColors.white,
        child: SafeArea(
          bottom: false, // Để nội dung tràn xuống dưới Nav
          child: RefreshIndicator(
            onRefresh: _loadData,
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
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primarySV.withValues(alpha: 0.15),
                            AppColors.lightSV.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.primarySV.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.lightBlue.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('Xin chào', style: TextStyle(fontSize: 14, color: AppColors.white, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userName,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primarySV),
                                ),
                                Text("MSSV: $_mssv", style: const TextStyle(color: AppColors.gray500, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.primarySV.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: const Icon(Icons.person_rounded, color: AppColors.primarySV, size: 35),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const SizedBox(height: 10),

                  // 2. Thống kê nhanh
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Thống kê nhanh', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: StreamBuilder<List<RequestModel>>(
                      stream: DbService().getStudentRequestsStream(user?.id ?? ''),
                      builder: (context, snapshot) {
                        int pending = 0, processing = 0, completed = 0, rejected = 0;
                        if (snapshot.hasData) {
                          final list = snapshot.data!;
                          pending = list.where((r) => r.status.name == 'pending').length;
                          processing = list.where((r) => r.status.name == 'processing').length;
                          completed = list.where((r) => r.status.name == 'completed').length;
                          rejected = list.where((r) => r.status.name == 'rejected').length;
                        }
                        return Column(
                          children: [
                            Row(
                              children: [
                                _buildStatCard('Chờ tiếp nhận', pending, AppColors.lightSV, AppColors.primarySV),
                                const SizedBox(width: 12),
                                _buildStatCard('Đang xử lý', processing, AppColors.warningLight, AppColors.warning),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildStatCard('Hoàn thành', completed, AppColors.successLight, AppColors.success),
                                const SizedBox(width: 12),
                                _buildStatCard('Đã huỷ', rejected, AppColors.dangerLight, AppColors.danger),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Tính năng chính
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Tính năng chính', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: _isExpanded ? 360 : 240, 
                        child: GridView.count(
                          crossAxisCount: 3,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          children: [
                            _buildFeatureItem('assets/icons/tnc_xnsv.png', Colors.purple, 'Xác nhận\nsinh viên'),
                            _buildFeatureItem('assets/icons/tnc_capbangdiem.png', Colors.green, 'Xin cấp\nbảng điểm'),
                            _buildFeatureItem('assets/icons/tnc_pkdiemthi.png', Colors.orange, 'Phúc khảo\nđiểm thi'),
                            _buildFeatureItem('assets/icons/tnc_dkhp.png', Colors.blue, 'Hủy\nhọc phần'),
                            _buildFeatureItem('assets/icons/tnc_hocphi.png', Colors.pink, 'Gia hạn\nhọc phí'),
                            
                            // Nút mở rộng xem thêm
                            _buildExpandButton(),
                            
                            // Các danh mục ẩn hiện động khi bấm Xem thêm
                            if (_isExpanded) ...[
                              _buildFeatureItem('assets/icons/tnc_lichthi.png', Colors.indigo, 'Đơn xin\nhoãn thi'),
                              _buildFeatureItem('assets/icons/tnc_dkkhoaluan.png', Colors.red, 'Bảo lưu\nhọc tập'),
                              _buildFeatureItem('assets/icons/tnc_bhyt.png', Colors.teal, 'Thôi học\nRút hồ sơ'),
                            ]
                          ],
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
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 30),
                        const SizedBox(height: 8),
                        const Text(
                          "Không thể cập nhật dữ liệu mới nhất. Vui lòng kiểm tra kết nối mạng.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.gray500),
                        ),
                        TextButton(
                          onPressed: _loadData, // Gọi lại hàm load để thử lại
                          child: const Text("Thử lại", style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                  const SizedBox(height: 120), // Khoảng trống để NavBar không che mất nội dung cuối
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  // Hàm hỗ trợ vẽ nút Xem thêm / Thu gọn
  Widget _buildExpandButton() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(
              _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.grid_view_rounded,
              color: Colors.blueGrey, size: 32,
            ),
          ),
          const SizedBox(height: 10),
          Text(_isExpanded ? 'Thu gọn' : 'Xem thêm', 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray900)),
        ],
      ),
    );
  }

  // Hàm hỗ trợ vẽ Thẻ thống kê (Hình tròn cho số đếm)
  Widget _buildStatCard(String title, int count, Color bgColor, Color mainColor) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng để đổ bóng rõ hơn
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: mainColor.withValues(alpha: 0.03), // Bóng đổ theo màu chủ đạo của thẻ
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mainColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: mainColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))
              ],
            ),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    ),
  );
}

// Hàm hỗ trợ vẽ Icon Tính năng (Đã thêm InkWell và đổi sang dùng ảnh Asset)
Widget _buildFeatureItem(String assetPath, Color baseColor, String title) {
  // Tạo màu Pastel cực nhạt cho nền
  final Color pastelColor = baseColor.withValues(alpha: 0.1);

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
      );
    },
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pastelColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: baseColor.withValues(alpha: 0.1), width: 1),
            boxShadow: [
              // ĐỔ BÓNG THEO MÀU ICON: Tạo hiệu ứng phát sáng nhẹ (Glow)
              BoxShadow(
                color: baseColor.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Image.asset(
            assetPath, 
            width: 34, 
            height: 34,
            errorBuilder: (context, error, stackTrace) => 
              Icon(Icons.extension_rounded, color: baseColor, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w600, 
            color: AppColors.gray900,
            height: 1.2,
          ),
        ),
      ],
    ),
  );
}
}

class SchoolNewsSection extends StatelessWidget {
  const SchoolNewsSection({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    // Sử dụng InAppWebView hoặc mở trình duyệt ngoài
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Không thể mở liên kết $url';
    }
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
              const Text(
                'Bảng tin nhà trường',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
              ),
              TextButton(
                onPressed: () => _launchURL('https://sinhvien.huit.edu.vn/sinh-vien/dm-tin-tuc/thong-tin-chung-095310.html'),
                child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primarySV)),
              )
            ],
          ),
        ),
        FutureBuilder<List<Map<String, String>>>(
          future: HuitScraperService.fetchAnnouncements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Column(
                    children: List.generate(3, (index) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    )),
                  ),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Không có tin tức mới'));
            }

            final newsList = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: newsList.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = newsList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _launchURL(item['link'] ?? ''),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon hoặc Ảnh minh họa nhỏ
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.lightSV,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.campaign_rounded, color: AppColors.primarySV, size: 24),
                          ),
                          const SizedBox(width: 12),
                          // Nội dung tin
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: AppColors.gray500),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['date'] ?? 'Tin mới',
                                      style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                                    ),
                                    const Spacer(),
                                    const Text('Xem chi tiết', style: TextStyle(fontSize: 12, color: AppColors.primarySV, fontWeight: FontWeight.w500)),
                                  ],
                                ),
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