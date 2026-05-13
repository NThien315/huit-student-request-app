import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/screens/student/search_screen.dart';
import '../../../core/theme.dart';
import 'create_request_screen.dart';
import 'package:provider/provider.dart';
import '../../../state/auth_provider.dart';
import '../../../services/db_service.dart';
import '../../../models/request_model.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ô tìm kiếm (Bo góc tròn dạng viên thuốc)
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                readOnly: true, // QUAN TRỌNG: Ngăn bật bàn phím ở trang chủ
                onTap: () {
                  // Chuyển sang màn hình tìm kiếm khi bấm vào
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchScreen()),
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm yêu cầu của bạn...',
                  hintStyle: const TextStyle(color: AppColors.gray500, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: AppColors.gray900, size: 26),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Thẻ Welcome (Đã kết nối Database)
            Builder(
              builder: (context) {
                // Rút thẳng thông tin User từ "bộ não" AuthProvider
                final authState = context.watch<AuthProvider>();
                final user = authState.currentUser;

                // Chuẩn bị dữ liệu (Nếu lỡ mạng chậm chưa lấy được thì để mặc định)
                final String name = user?.displayName ?? 'Sinh viên';
                final String studentId = user?.studentId ?? 'Đang cập nhật...';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.lightSV,
                    borderRadius: BorderRadius.circular(20), // Vẫn giữ nguyên bo góc tuyệt đẹp của bạn
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào, $name', // Lấy tên thật từ biến
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'MSSV: $studentId', // Lấy MSSV thật từ biến
                        style: const TextStyle(fontSize: 14, color: AppColors.gray500),
                      ),
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 18),

            // 3. Thống kê nhanh
            const Text(
              'Thống kê nhanh',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900),
            ),
            const SizedBox(height: 16),
            
            // Dùng StreamBuilder để đếm số lượng đơn
            StreamBuilder<List<RequestModel>>(
              stream: DbService().getStudentRequests(context.read<AuthProvider>().currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                // Khởi tạo các biến đếm mặc định là 0
                int pendingCount = 0;
                int processingCount = 0;
                int completedCount = 0;
                int rejectedCount = 0;

                // Nếu load được dữ liệu thật thì tiến hành đếm
                if (snapshot.hasData && snapshot.data != null) {
                  final list = snapshot.data!;
                  pendingCount = list.where((r) => r.status.name == 'pending').length;
                  processingCount = list.where((r) => r.status.name == 'processing').length;
                  completedCount = list.where((r) => r.status.name == 'completed').length;
                  rejectedCount = list.where((r) => r.status.name == 'rejected').length;
                }

                // Vẽ giao diện CŨ CỦA BẠN với con số MỚI
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard('Chờ tiếp nhận', pendingCount, AppColors.lightSV, AppColors.primarySV),
                        const SizedBox(width: 12),
                        _buildStatCard('Đang xử lý', processingCount, AppColors.warningLight, AppColors.warning),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatCard('Hoàn thành', completedCount, AppColors.successLight, AppColors.success),
                        const SizedBox(width: 12),
                        _buildStatCard('Đã huỷ', rejectedCount, AppColors.dangerLight, AppColors.danger),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

            // 4. Tính năng chính
            const Text(
              'Tính năng chính',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3, // Số cột
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 0,
              crossAxisSpacing: 12, 
              childAspectRatio: 1,
              children: [
                _buildFeatureItem(
                  'assets/icons/tnc_dkhp.png',
                  AppColors.success, 
                  'Đăng ký\nhọc phần',
                  () {
                    Navigator.push(
                      context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRequestScreen(
                            initialRequestType: 'Đăng ký học phần',
                          ),
                        ),
                    );
                  }
                ),
                _buildFeatureItem(
                  'assets/icons/tnc_capbangdiem.png',
                  AppColors.success, 
                  'Xin cấp\nbảng điểm',
                  () {
                    Navigator.push(
                      context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRequestScreen(
                            initialRequestType: 'Xin cấp bảng điểm',
                          ),
                        ),
                    );
                  }
                ),
                _buildFeatureItem(
                  'assets/icons/tnc_pkdiemthi.png', 
                  AppColors.success, 
                  'Phúc khảo\nđiểm thi',
                  () {
                    Navigator.push(
                      context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRequestScreen(
                            initialRequestType: 'Phúc khảo điểm thi',
                          ),
                        ),
                    );
                  }
                ),
                _buildFeatureItem(
                  'assets/icons/tnc_dkkhoaluan.png',
                  AppColors.success, 
                  'Đăng ký\nkhoá luận',
                  () {
                    Navigator.push(
                      context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRequestScreen(
                            initialRequestType: 'Đăng ký khoá luận',
                          ),
                        ),
                    );
                  }
                ),
                _buildFeatureItem(
                  'assets/icons/tnc_xnsv.png',
                  AppColors.success, 
                  'Xin cấp giấy xác\nnhận sinh viên',
                  () {
                    Navigator.push(
                      context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRequestScreen(
                            initialRequestType: 'Xin cấp giấy xác nhận sinh viên',
                          ),
                        ),
                    );
                  }
                ),
                _buildFeatureItem(
                  'assets/icons/tnc_xemthem.png', 
                  AppColors.success, 
                  'Xem thêm\n',
                  () {
                    Navigator.push(
                      context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRequestScreen(
                            initialRequestType: 'Xem thêm',
                          ),
                        ),
                    );
                  }
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hỗ trợ vẽ Thẻ thống kê (Hình tròn cho số đếm)
  Widget _buildStatCard(String title, int count, Color bgColor, Color mainColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16), // Bo góc
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: mainColor,
                shape: BoxShape.circle, // Đổi thành hình tròn
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hỗ trợ vẽ Icon Tính năng (Đã thêm InkWell và đổi sang dùng ảnh Asset)
  Widget _buildFeatureItem(String assetPath, Color color, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent, // Phải có Material để InkWell hiển thị hiệu ứng
      child: InkWell(
        onTap: onTap, // Hành động khi bấm vào
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // DÙNG ẢNH FIGMA CỦA BẠN Ở ĐÂY
            Image.asset(assetPath, width: 42, height: 42), 
            
            // Tạm thời mình vẫn để Icon mặc định để app bạn không bị lỗi khi chưa có ảnh
            //Icon(Icons.dashboard, color: color, size: 42), 
            
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.gray900, height: 1.3, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}