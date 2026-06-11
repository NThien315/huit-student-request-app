// lib/ui/screens/staff/staff_category_screen.dart
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/state/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';

class StaffCategoryScreen extends StatefulWidget {
  const StaffCategoryScreen({super.key});

  @override
  State<StaffCategoryScreen> createState() => _StaffCategoryScreenState();
}

class _StaffCategoryScreenState extends State<StaffCategoryScreen> with SingleTickerProviderStateMixin {
  String _searchTerm = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fetchCategories();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client.from('request_categories').select().order('id', ascending: true);
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        _animController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCategoryStatus(dynamic id, bool currentValue) async {
    try {
      setState(() {
        final index = _categories.indexWhere((c) => c['id'] == id);
        if (index != -1) _categories[index]['isActive'] = !currentValue;
      });
      await Supabase.instance.client.from('request_categories').update({'isActive': !currentValue}).eq('id', id);
    } catch (e) {
      setState(() {
        final index = _categories.indexWhere((c) => c['id'] == id);
        if (index != -1) _categories[index]['isActive'] = currentValue;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật trạng thái!')));
    }
  }

  Future<void> _deleteCategory(dynamic id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.danger), SizedBox(width: 8), Text('Xác nhận xóa')]),
        content: Text('Bạn có chắc chắn muốn xóa danh mục "$name" không?\nLưu ý: Nếu danh mục này đã có đơn nộp, hệ thống sẽ từ chối xóa để bảo vệ dữ liệu lịch sử.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: AppColors.gray500))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa danh mục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('request_categories').delete().eq('id', id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa danh mục thành công!'), backgroundColor: AppColors.success));
      _fetchCategories();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa! Danh mục này đang được sử dụng trong các Đơn yêu cầu.'), backgroundColor: AppColors.danger));
    }
  }

  void _showAddEditDialog([Map<String, dynamic>? categoryToEdit]) {
    final isEditing = categoryToEdit != null;
    final nameController = TextEditingController(text: isEditing ? categoryToEdit['name'] : '');
    final descController = TextEditingController(text: isEditing ? (categoryToEdit['description'] ?? '') : '');
    
    final List<String> slaOptions = ['Trong ngày (24h)', '1 - 2 ngày', '2 - 3 ngày', '3 - 5 ngày', '1 tuần', '2 tuần'];
    String selectedSla = isEditing ? (categoryToEdit['sla'] ?? '1 - 2 ngày') : '1 - 2 ngày';
    if (!slaOptions.contains(selectedSla)) slaOptions.add(selectedSla);

    String selectedDept = isEditing ? (categoryToEdit['department'] ?? 'khoa') : 'khoa';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 550, padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? 'Chỉnh sửa Danh mục' : 'Thêm Danh mục mới', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  const SizedBox(height: 24),
                  
                  const Text('Tên loại yêu cầu', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  const SizedBox(height: 8),
                  TextField(controller: nameController, decoration: _inputDeco('Vd: Chuyển nhóm thực hành / Đổi ca')),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Phòng ban xử lý (*)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedDept, decoration: _inputDeco('Chọn nơi xử lý'),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gray500),
                              items: const [
                                DropdownMenuItem(value: 'ctsv', child: Text('Phòng CTSV (Hành chính)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                DropdownMenuItem(value: 'khoa', child: Text('VP Khoa (Học vụ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              ],
                              onChanged: (val) { if (val != null) setDialogState(() => selectedDept = val); },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hạn xử lý (SLA) (*)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedSla, decoration: _inputDeco('Chọn thời gian'),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gray500),
                              items: slaOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (val) { if (val != null) setDialogState(() => selectedSla = val); },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Text('Mô tả chi tiết loại yêu cầu', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  const SizedBox(height: 8),
                  TextField(controller: descController, maxLines: 3, decoration: _inputDeco('Nhập mô tả hướng dẫn sinh viên chuẩn bị giấy tờ...')),
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: AppColors.gray500, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty) return;
                          final data = {
                            'name': nameController.text.trim(),
                            'description': descController.text.trim().isEmpty ? 'Hướng dẫn nộp theo quy định' : descController.text.trim(),
                            'sla': selectedSla,
                            'department': selectedDept, 
                          };
                          try {
                            if (isEditing) {
                              await Supabase.instance.client.from('request_categories').update(data).eq('id', categoryToEdit['id']);
                            } else {
                              await Supabase.instance.client.from('request_categories').insert(data);
                            }
                            if (context.mounted) Navigator.pop(context);
                            _fetchCategories();
                          } catch (e) {
                            debugPrint('Lỗi lưu danh mục: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySV, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo danh mục', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: AppColors.gray100, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySV)));

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _categories.where((cat) => cat['name'].toString().toLowerCase().contains(_searchTerm.toLowerCase())).toList();
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isAdmin = currentUser?.role.name == 'admin'; // Fix Enum Warning
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primarySV))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                // FIX UI BẰNG WRAP CHO HEADER
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 16, runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quản lý Danh mục', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gray900, letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          Text('Đang quản lý ${filteredCategories.length} loại yêu cầu hệ thống học vụ', style: const TextStyle(fontSize: 15, color: AppColors.gray500, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Wrap(
                        spacing: 16, runSpacing: 16,
                        children: [
                          SizedBox(
                            width: 280,
                            child: TextField(
                              onChanged: (val) => setState(() => _searchTerm = val),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm danh mục...', prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray500), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySV, width: 1.5)),
                              ),
                            ),
                          ),
                          if (isAdmin)
                            ElevatedButton.icon(
                              onPressed: () => _showAddEditDialog(), 
                              icon: const Icon(Icons.add_rounded, color: Colors.white),
                              label: const Text('Thêm loại đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarySV, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filteredCategories.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.category_outlined, size: 80, color: AppColors.gray200), const SizedBox(height: 16), const Text('Không tìm thấy danh mục nào khớp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900))]))
                  // FIX UI BẰNG CÁCH BỌC CUỘN NGANG CHO LISTVIEW
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1000,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8), itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final cat = filteredCategories[index];
                            return _StaggeredListItem(
                              index: index, controller: _animController,
                              child: _CategoryItemCard(
                                category: cat,
                                onToggle: (val) => _toggleCategoryStatus(cat['id'], cat['isActive']),
                                onEdit: () => _showAddEditDialog(cat),
                                onDelete: () => _deleteCategory(cat['id'], cat['name']),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
              ),
            ],
          ),
    );
  }
}

class _StaggeredListItem extends StatelessWidget {
  final int index; final AnimationController controller; final Widget child;
  const _StaggeredListItem({required this.index, required this.controller, required this.child});
  @override
  Widget build(BuildContext context) {
    final delay = (index * 0.03).clamp(0.0, 1.0);
    final animation = CurvedAnimation(parent: controller, curve: Interval(delay, 1.0, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: animation, builder: (context, child) => Transform.translate(offset: Offset(0, 20 * (1 - animation.value)), child: Opacity(opacity: animation.value, child: child)), child: child,
    );
  }
}

class _CategoryItemCard extends StatefulWidget {
  final Map<String, dynamic> category; final Function(bool) onToggle; final VoidCallback onEdit; final VoidCallback onDelete;
  const _CategoryItemCard({required this.category, required this.onToggle, required this.onEdit, required this.onDelete});
  @override
  State<_CategoryItemCard> createState() => _CategoryItemCardState();
}

class _CategoryItemCardState extends State<_CategoryItemCard> {
  bool _isHovered = false;

  IconData _getDynamicIcon(String catName) {
    final name = catName.toLowerCase();
    if (name.contains('học phí') || name.contains('học bổng')) return Icons.account_balance_wallet_rounded;
    if (name.contains('thẻ sinh viên')) return Icons.badge_rounded;
    if (name.contains('điểm')) return Icons.fact_check_rounded;
    if (name.contains('tốt nghiệp')) return Icons.school_rounded;
    if (name.contains('thực tập')) return Icons.business_center_rounded;
    if (name.contains('hủy') || name.contains('thôi học')) return Icons.disabled_by_default_rounded;
    if (name.contains('hoãn thi') || name.contains('bảo lưu')) return Icons.pending_actions_rounded;
    return Icons.assignment_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final bool isActive = cat['isActive'] ?? false;
    final String dept = cat['department'] ?? 'khoa';
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isAdmin = currentUser?.role.name == 'admin';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : AppColors.gray100.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _isHovered ? AppColors.primarySV.withValues(alpha: 0.3) : AppColors.gray200, width: 1.5),
          boxShadow: [if (_isHovered) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isActive ? AppColors.primarySV.withValues(alpha: 0.1) : AppColors.gray300, borderRadius: BorderRadius.circular(12)),
              child: Icon(_getDynamicIcon(cat['name'] ?? ''), color: isActive ? AppColors.primarySV : AppColors.gray500, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(child: Text(cat['name'] ?? '', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: isActive ? AppColors.gray900 : AppColors.gray500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 12),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: dept == 'ctsv' ? Colors.purple.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(dept == 'ctsv' ? 'Phòng CTSV' : 'Khoa CNTT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dept == 'ctsv' ? Colors.purple : Colors.blue))),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.gray200, borderRadius: BorderRadius.circular(20)), child: Text(isActive ? 'Hoạt động' : 'Tạm ngưng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? AppColors.success : AppColors.gray500))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(cat['description'] ?? 'Danh mục yêu cầu học vụ sinh viên HDPE.', style: TextStyle(color: isActive ? AppColors.gray500 : AppColors.gray500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Hạn xử lý', style: TextStyle(fontSize: 10, color: AppColors.gray500, fontWeight: FontWeight.w600)), const SizedBox(height: 2),
                  Row(children: [const Icon(Icons.timer_outlined, size: 13, color: AppColors.gray900), const SizedBox(width: 4), Text(cat['sla'] ?? '1-3 ngày', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900, fontSize: 12.5))])
                ],
              ),
            ),
            const SizedBox(width: 28),
            Row(
              children: [
                Switch(value: isActive, activeThumbColor: AppColors.primarySV, onChanged: widget.onToggle),
                const SizedBox(width: 8),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.gray500, size: 20), tooltip: 'Chỉnh sửa', onPressed: widget.onEdit),
                  IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20), tooltip: 'Xóa danh mục', onPressed: widget.onDelete),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}