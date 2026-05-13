import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'request_detail_screen.dart'; 
import '../../../services/db_service.dart';
import '../../../models/request_model.dart';
import 'package:provider/provider.dart';
import '../../../state/auth_provider.dart';

final DbService _dbService = DbService();

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Biến lưu trữ từ khóa tìm kiếm
  String _searchQuery = '';


  // Hàm dịch mã Code thành chữ để hiển thị trên Thẻ
  String _getStatusName(int code) {
    switch (code) {
      case 0: return 'Đã huỷ';
      case 1: return 'Chờ tiếp nhận';
      case 2: return 'Đang xử lý';
      case 3: return 'Cần bổ sung';
      case 4: return 'Hoàn thành';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Lịch sử', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              ),
              
              // Ô tìm kiếm có sự kiện onChanged
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase(); // Chuyển chữ thường để dễ tìm
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm',
                    hintStyle: const TextStyle(color: AppColors.gray500),
                    prefixIcon: const Icon(Icons.search, color: AppColors.gray900),
                    filled: true,
                    fillColor: AppColors.gray100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: 16),
                labelColor: AppColors.gray900,
                unselectedLabelColor: AppColors.gray500,
                indicatorColor: AppColors.primarySV,
                indicatorWeight: 3,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Chờ tiếp nhận'),
                  Tab(text: 'Đang xử lý'),
                  Tab(text: 'Hoàn thành'),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: Builder( // 👉 Bỏ FutureBuilder, thay bằng Builder
                  builder: (context) {
                    // 👉 1. Lấy thẳng thông tin user từ bộ não (Không bị vòng lặp)
                    final authState = context.watch<AuthProvider>();
                    final currentUser = authState.currentUser;

                    if (currentUser == null) {
                      return const Center(child: Text('Vui lòng đăng nhập để xem lịch sử'));
                    }

                    final studentUid = currentUser.uid;

                    // 2. Lắng nghe dữ liệu Lịch sử Real-time từ Firestore
                    return StreamBuilder<List<RequestModel>>(
                      stream: _dbService.getStudentRequests(studentUid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Bạn chưa có yêu cầu nào.'));
                        }

                        final allRequests = snapshot.data!;

                        // 3. Phân loại yêu cầu theo Tab
                        return TabBarView(
                          children: [
                            _buildRequestList(allRequests), // Tab: Tất cả
                            _buildRequestList(allRequests.where((r) => r.status.name == 'pending').toList()), // Chờ tiếp nhận
                            _buildRequestList(allRequests.where((r) => r.status.name == 'processing').toList()), // Đang xử lý
                            _buildRequestList(allRequests.where((r) => r.status.name == 'completed').toList()), // Hoàn thành
                            _buildRequestList(allRequests.where((r) => r.status.name == 'rejected').toList()), // Đã huỷ/Từ chối
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm tạo danh sách sau khi đã LỌC TÌM KIẾM và LỌC TAB
  Widget _buildRequestList(List<RequestModel> requests) {
    // 1. Lọc dữ liệu theo ô tìm kiếm
    final filteredData = requests.where((request) {
      // Tìm theo tên danh mục (title)
      return request.categoryName.toLowerCase().contains(_searchQuery);
    }).toList();

    // 2. Hiển thị UI trống nếu không tìm thấy
    if (filteredData.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy kết quả nào', style: TextStyle(color: AppColors.gray500)),
      );
    }

    // 3. Hiển thị danh sách kết quả thật
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final request = filteredData[index]; // Đây là dữ liệu thật từ TV2
        
        // Chuyển đổi trạng thái từ TV2 sang UI của bạn
        Color statusColor = AppColors.primarySV;
        IconData statusIcon = Icons.more_horiz;
        int statusCode = 1;

        switch (request.status.name) {
          case 'pending':
            statusColor = AppColors.primarySV; statusIcon = Icons.more_horiz; statusCode = 1; break;
          case 'processing':
            statusColor = AppColors.warning; statusIcon = Icons.hourglass_empty; statusCode = 2; break;
          case 'completed':
            statusColor = AppColors.success; statusIcon = Icons.check; statusCode = 4; break;
          case 'rejected':
            statusColor = AppColors.danger; statusIcon = Icons.close; statusCode = 0; break;
        }

        return _buildRequestCard(
          context: context,
          request: request,
          title: request.categoryName, // Lấy tên yêu cầu
          // Format ngày tháng (có thể dùng package intl để format đẹp hơn sau)
          date: "${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}", 
          statusCode: statusCode, 
          statusColor: statusColor,
          icon: statusIcon,
        );
      },
    );
  }

  Widget _buildRequestCard({
    required BuildContext context, 
    required RequestModel request,
    required String title, 
    required String date,
    required int statusCode, 
    required Color statusColor, 
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailScreen(request: request), // Truyền nguyên model thật
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), // Giảm khoảng cách giữa các thẻ một chút
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Giảm padding dọc giúp thẻ thon gọn hơn
        decoration: BoxDecoration(
          color: AppColors.white, 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor, width: 1.2), // Viền mảnh lại một chút cho thanh thoát
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Icon bên trái (Thu nhỏ nhẹ)
            Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 18), // Size 20 -> 18
            ),
            const SizedBox(width: 14), // Khoảng cách icon và chữ
            
            // 2. Nội dung ở giữa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title, 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900),
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text('Ngày gửi: $date', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            
            // 3. Viên thuốc trạng thái (Căn giữa thẻ, thay thế mũi tên)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(
                _getStatusName(statusCode), 
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}