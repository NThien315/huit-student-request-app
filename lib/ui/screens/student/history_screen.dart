// lib/ui/screens/student/history_screen.dart
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/screens/student/request_detail_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../../core/theme.dart';
import '../../../models/request_model.dart';
import '../../../state/auth_provider.dart';
import 'package:flutter/services.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true; 

  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Chờ tiếp nhận', 'Đang xử lý', 'Hoàn thành', 'Đã huỷ'];
  
  String _searchQuery = '';
  late Stream<List<Map<String, dynamic>>> _requestsStream;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    
    _requestsStream = Supabase.instance.client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('studentUid', user?.uid ?? '')
        .order('createdAt', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            color: AppColors.white,
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildSearchBar()),
                    SliverToBoxAdapter(child: const SizedBox(height: 12)),
                    SliverToBoxAdapter(child: _buildModernFilterBar()),
                    
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _requestsStream, 
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(child: Text('Lỗi kết nối dữ liệu: ${snapshot.error}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            ),
                          );
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return SliverToBoxAdapter(child: _buildShimmerLoading());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState());
                        }

                        final requests = snapshot.data!;
                        
                        final filteredList = requests.where((req) {
                          final status = (req['status'] ?? 'pending').toString().toLowerCase();
                          final categoryName = (req['categoryName'] ?? '').toString();
                          
                          // ─── THUẬT TOÁN TẠO MÃ ĐƠN ĐỂ TÌM KIẾM ───
                          final date = DateTime.parse(req['createdAt'] ?? DateTime.now().toIso8601String()).toLocal();
                          final shortId = req['id'].toString().substring(req['id'].toString().length - 4).toUpperCase();
                          String prefix = 'RQ';
                          if (categoryName.isNotEmpty) {
                            prefix = categoryName.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join('');
                          }
                          final formattedId = '#$prefix-${date.day}${date.month}-$shortId'.toLowerCase();
                          // ─────────────────────────────────────────────

                          final matchesFilter = _selectedFilter == 'Tất cả' || _getStatusLabel(status) == _selectedFilter;
                          
                          final searchLower = _searchQuery.toLowerCase();
                          // KẾT HỢP TÌM KIẾM CẢ TÊN ĐƠN LẪN MÃ ĐƠN
                          final matchesSearch = categoryName.toLowerCase().contains(searchLower) || formattedId.contains(searchLower);
                          
                          return matchesFilter && matchesSearch;
                        }).toList();

                        if (filteredList.isEmpty) {
                          return const SliverToBoxAdapter(
                            child: Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text("Không tìm thấy yêu cầu nào", style: TextStyle(color: AppColors.gray500)))),
                          );
                        }

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

  Widget _buildHeader() {
    return const Padding(padding: EdgeInsets.all(24.0), child: Text('Lịch sử yêu cầu', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gray900)));
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(hintText: 'Tìm kiếm mã (#RQ...) hoặc tên...', hintStyle: const TextStyle(color: AppColors.gray500, fontSize: 14), prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray500), filled: true, fillColor: AppColors.gray100.withValues(alpha: 0.5), contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
      ),
    );
  }

  Widget _buildModernFilterBar() {
    return SizedBox(
      height: 60, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), clipBehavior: Clip.none, itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index]; final isSelected = _selectedFilter == filter; final filterColor = _getFilterColor(filter); 
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 18), 
              decoration: BoxDecoration(color: isSelected ? filterColor : AppColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? filterColor : AppColors.gray200), boxShadow: isSelected ? [BoxShadow(color: filterColor.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 3))] : []),
              child: Center(child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : AppColors.gray500, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13))),
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
      default: return AppColors.primarySV;
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = (request['status'] ?? 'pending').toString().toLowerCase();
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusLabel(status);

    final date = DateTime.parse(request['createdAt'] ?? DateTime.now().toIso8601String()).toLocal();
    final shortId = request['id'].toString().substring(request['id'].toString().length - 4).toUpperCase();
    
    String prefix = 'RQ';
    final String categoryName = request['categoryName'] ?? '';
    if (categoryName.isNotEmpty) {
      prefix = categoryName.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join('');
    }
    final formattedId = '#$prefix-${date.day}${date.month}-$shortId';
    final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.2), boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.12), blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 4))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          final requestModel = RequestModel(
            id: request['id'] ?? '',
            studentUid: request['studentUid'] ?? '',
            studentName: request['studentName'] ?? '',
            studentId: request['studentId'] ?? '',
            categoryId: request['categoryId'].toString(),
            categoryName: categoryName,
            subjectCode: request['subjectCode'] ?? '',
            reason: request['reason'] ?? '',
            attachmentUrls: List<String>.from(request['attachmentUrls'] ?? []),
            status: RequestStatus.pending, 
            createdAt: date,
            updatedAt: date,
          );

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RequestDetailScreen(request: requestModel)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(_getStatusIcon(status), color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(categoryName, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.gray900), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(formattedId, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(timeStr, style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFilterLabel(String status) => _getStatusLabel(status);

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Chờ tiếp nhận';
      case 'processing': return 'Đang xử lý';
      case 'completed':
      case 'approved': return 'Hoàn thành';
      case 'rejected': return 'Đã huỷ';
      default: return 'Không xác định';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.blue;
      case 'processing': return Colors.orange;
      case 'completed':
      case 'approved': return Colors.green; 
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.timer_outlined;
      case 'processing': return Icons.sync_rounded;
      case 'completed':
      case 'approved': return Icons.check_circle_outline_rounded;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.help_outline_rounded;
    }
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
        child: Column(children: List.generate(5, (index) => Container(margin: const EdgeInsets.only(bottom: 16), height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_edu_rounded, size: 80, color: AppColors.gray200), const SizedBox(height: 16), const Text("Bạn chưa có yêu cầu nào", style: TextStyle(color: AppColors.gray500, fontSize: 16))]));
  }
}