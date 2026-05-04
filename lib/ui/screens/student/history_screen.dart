import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'request_detail_screen.dart'; 

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Biến lưu trữ từ khóa tìm kiếm
  String _searchQuery = '';

  // Dữ liệu mẫu (Giả lập Database)
  final List<Map<String, dynamic>> _mockRequests = [
    {
      'title': 'Xin bảng điểm', 'date': '12/04/2026', 
      'statusCode': 4, // 4: Hoàn thành
      'color': AppColors.success, 'icon': Icons.check_circle, 'tab': 'Hoàn thành'
    },
    {
      'title': 'Phúc khảo điểm thi', 'date': '11/04/2026', 
      'statusCode': 1, // 1: Chờ tiếp nhận
      'color': AppColors.primarySV, 'icon': Icons.more_horiz, 'tab': 'Chờ tiếp nhận'
    },
    {
      'title': 'Xác nhận vay vốn sinh viên', 'date': '10/04/2026', 
      'statusCode': 3, // 3: Cần bổ sung
      'color': AppColors.warning, 'icon': Icons.hourglass_bottom, 'tab': 'Đang xử lý'
    },
    {
      'title': 'Đăng ký xét tốt nghiệp', 'date': '09/04/2026', 
      'statusCode': 0, // 0: Đã huỷ
      'color': AppColors.danger, 'icon': Icons.cancel, 'tab': 'Tất cả' 
    },
  ];

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
                child: TabBarView(
                  children: [
                    _buildRequestList(tabFilter: 'Tất cả'),
                    _buildRequestList(tabFilter: 'Chờ tiếp nhận'),
                    _buildRequestList(tabFilter: 'Đang xử lý'), 
                    _buildRequestList(tabFilter: 'Hoàn thành'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm tạo danh sách sau khi đã LỌC TÌM KIẾM và LỌC TAB
  Widget _buildRequestList({required String tabFilter}) {
    // 1. Lọc dữ liệu
    final filteredData = _mockRequests.where((item) {
      // Kiểm tra xem tên yêu cầu có chứa từ khóa không
      final matchesSearch = item['title'].toString().toLowerCase().contains(_searchQuery);
      // Kiểm tra xem nó có thuộc Tab hiện tại không
      final matchesTab = tabFilter == 'Tất cả' || item['tab'] == tabFilter;
      
      return matchesSearch && matchesTab;
    }).toList();

    // 2. Hiển thị UI trống nếu không tìm thấy
    if (filteredData.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy kết quả nào', style: TextStyle(color: AppColors.gray500)),
      );
    }

    // 3. Hiển thị danh sách kết quả
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final data = filteredData[index];
        return _buildRequestCard(
          context: context,
          title: data['title'],
          date: data['date'],
          statusCode: data['statusCode'], // TRUYỀN INT VÀO ĐÂY
          statusColor: data['color'],
          icon: data['icon'],
        );
      },
    );
  }

  Widget _buildRequestCard({
    required BuildContext context, 
    required String title, 
    required String date,
    required int statusCode, 
    required Color statusColor, 
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => RequestDetailScreen(
          title: title, statusCode: statusCode, color: statusColor, icon: icon,
        )));
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