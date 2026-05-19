import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/screens/student/request_detail_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/request_model.dart';
import '../../../services/db_service.dart';
import '../../../state/auth_provider.dart';
import 'package:flutter/services.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

// Sử dụng AutomaticKeepAliveClientMixin để chuyển tab không bị load lại
class _HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Chờ tiếp nhận', 'Đang xử lý', 'Hoàn thành', 'Đã huỷ'];
  
  // Thêm biến cho Thanh tìm kiếm và Stream
  String _searchQuery = '';
  late Stream<List<RequestModel>> _requestsStream;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _requestsStream = DbService().getStudentRequestsStream(user?.uid ?? '');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark, // Ép icon pin/mạng màu tối (đen)
        child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          color: AppColors.white,
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 800));
              },
              // CHUYỂN SANG DÙNG CustomScrollView ĐỂ CUỘN TOÀN TRANG
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: const SizedBox(height: 12)),
                  SliverToBoxAdapter(child: _buildModernFilterBar()),
                  
                  // StreamBuilder giờ trả về các Sliver thay vì Widget thường
                  StreamBuilder<List<RequestModel>>(
                    stream: _requestsStream, 
                    builder: (context, snapshot) {
                      // Hiển thị trực tiếp lỗi lên màn hình nếu Stream thất bại
                      if (snapshot.hasError) {
                        debugPrint("🚨 LỖI PHÁT SINH TỪ STREAM: ${snapshot.error}");
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'Lỗi kết nối dữ liệu: ${snapshot.error}', 
                                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }

                      // 2. Trạng thái đang đợi tải dữ liệu
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SliverToBoxAdapter(child: _buildShimmerLoading());
                      }

                      // 3. Kiểm tra dữ liệu an toàn trước khi ép tiến trình đọc dữ liệu (!), tránh lỗi Null check
                      if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        );
                      }

                      // 4. Lọc danh sách khi đã chắc chắn data không bị null
                      final requests = snapshot.data!;
                      final filteredList = requests.where((req) {
                        final matchesFilter = _selectedFilter == 'Tất cả' || _getStatusLabel(req.status.name) == _selectedFilter;
                        final matchesSearch = req.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
                        return matchesFilter && matchesSearch;
                      }).toList();

                      if (filteredList.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: Text("Không tìm thấy yêu cầu nào", style: TextStyle(color: AppColors.gray500))),
                          ),
                        );
                      }

                      // 5. Hiển thị danh sách thẻ đơn
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildRequestCard(filteredList[index]),
                            childCount: filteredList.length,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  // --- WIDGET GIAO DIỆN ---

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Text(
        'Lịch sử yêu cầu',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gray900),
      ),
    );
  }

  // --- GIAO DIỆN TÌM KIẾM ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm đơn (VD: Xin bảng điểm)...',
          hintStyle: const TextStyle(color: AppColors.gray500, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray500),
          filled: true,
          fillColor: AppColors.gray100.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // --- GIAO DIỆN BỘ LỌC (Thay thế ChoiceChip) ---
  Widget _buildModernFilterBar() {
    return SizedBox(
      height: 60, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
        clipBehavior: Clip.none, 
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          final filterColor = _getFilterColor(filter); 

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18), 
              decoration: BoxDecoration(
                // Đổ màu theo filterColor thay vì primarySV
                color: isSelected ? filterColor : AppColors.white, 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? filterColor : AppColors.gray200,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: filterColor.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 3))
                ] : [],
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    // Nút không chọn thì hiện màu của trạng thái đó cho sinh động (tuỳ chọn)
                    color: isSelected ? Colors.white : AppColors.gray500,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Chờ tiếp nhận': return Colors.blue;
      case 'Đang xử lý': return Colors.orange;
      case 'Hoàn thành': return Colors.green;
      case 'Đã huỷ': return Colors.red;
      default: return AppColors.primarySV; // Dành cho nút 'Tất cả'
    }
  }

  Widget _buildRequestCard(RequestModel request) {
    final statusColor = _getStatusColor(request.status.name);
    final statusText = _getStatusLabel(request.status.name);

    // 1. Logic tạo mã đơn tự động giống trang Chi tiết
    final date = request.createdAt;
    final shortId = request.id.substring(request.id.length - 4).toUpperCase();
    String prefix = 'RQ';
    if (request.categoryName.isNotEmpty) {
      prefix = request.categoryName.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join('');
    }
    final formattedId = '#$prefix-${date.day}${date.month}-$shortId';

    // 2. Định dạng thời gian chi tiết (Giờ:Phút - Ngày/Tháng/Năm)
    final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RequestDetailScreen(request: request)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Đẩy các phần tử lên đỉnh để không lệch khi nhiều text
            children: [
              // Icon trạng thái
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(_getStatusIcon(request.status.name), color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              
              // Khối thông tin chi tiết
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tên danh mục (Đăng ký học phần, Xin bảng điểm...)
                    Text(
                      request.categoryName,
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.gray900),
                    ),
                    const SizedBox(height: 6),
                    
                    // Mã đơn & Thời gian trên cùng một hàng để tiết kiệm diện tích
                    Text(formattedId, style: const TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    
                    Text(timeStr, style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Nhãn trạng thái bên phải ngoài cùng
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HÀM HỖ TRỢ LOGIC ---

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Chờ tiếp nhận';
      case 'processing': return 'Đang xử lý';
      case 'completed': return 'Hoàn thành';
      case 'rejected': return 'Đã huỷ';
      default: return 'Không xác định';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.blue;
      case 'processing': return Colors.orange;
      case 'completed': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.timer_outlined;
      case 'processing': return Icons.sync_rounded;
      case 'completed': return Icons.check_circle_outline_rounded;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.help_outline_rounded;
    }
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        // Thay đổi hoàn toàn từ ListView sang Column để tránh lỗi "unbounded height"
        child: Column(
          children: List.generate(5, (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(24),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 80, color: AppColors.gray200),
          const SizedBox(height: 16),
          const Text("Bạn chưa có yêu cầu nào", style: TextStyle(color: AppColors.gray500, fontSize: 16)),
        ],
      ),
    );
  }
}