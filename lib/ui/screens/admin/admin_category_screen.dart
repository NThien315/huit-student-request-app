// lib/ui/screens/admin/admin_category_screen.dart
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/services/db_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../widgets/glass_toast.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  String _searchTerm = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await Supabase.instance.client.from('request_categories').select().order('id');
      if (mounted) setState(() { _categories = List<Map<String, dynamic>>.from(response); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(dynamic id, bool currentVal) async {
    try {
      setState(() => _categories.firstWhere((c) => c['id'] == id)['isActive'] = !currentVal); 
      await Supabase.instance.client.from('request_categories').update({'isActive': !currentVal}).eq('id', id);
      await DbService().logAudit('UPDATE', 'Trạng thái Danh mục', 'Đã thay đổi trạng thái hoạt động của danh mục ID: $id');
    } catch (e) {
      _fetchCategories();
    }
  }

  Future<void> _deleteCategory(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Xóa', style: TextStyle(color: AppColors.danger)),
        content: const Text('Bạn có chắc muốn xóa vĩnh viễn danh mục này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy', style: TextStyle(color: AppColors.gray500))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.white))),
        ],
      )
    );

    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('request_categories').delete().eq('id', id);
      // Lấy tên danh mục để ghi log
      final deletedCategory = _categories.firstWhere((cat) => cat['id'] == id, orElse: () => {'name': 'Không rõ'});
      final categoryName = deletedCategory['name'] ?? 'Không rõ';
      await DbService().logAudit('DELETE', 'Danh mục Yêu cầu', 'Đã xóa vĩnh viễn danh mục "$categoryName" (ID: $id)');
      if (!context.mounted) return;
      GlassToast.show(context, 'Đã xóa danh mục!');
      _fetchCategories();
    } catch (e) {
      if (!context.mounted) return;
      GlassToast.show(context, 'Lỗi: Danh mục đang được sử dụng, không thể xóa!', isError: true);
    }
  }

  void _showAddEditDialog([Map<String, dynamic>? category]) {
    final isEditing = category != null;
    final nameCtrl = TextEditingController(text: isEditing ? category['name'] : '');
    final descCtrl = TextEditingController(text: isEditing ? category['description'] : '');
    String selectedDept = isEditing ? (category['department'] ?? 'khoa') : 'khoa';
    String selectedSla = isEditing ? (category['sla'] ?? '1-2 ngày') : '1-2 ngày';
    final slaOptions = ['Trong ngày', '1-2 ngày', '3-5 ngày', '1 tuần'];
    if (!slaOptions.contains(selectedSla)) slaOptions.add(selectedSla);

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
                  Text(isEditing ? 'Sửa Danh mục' : 'Thêm Danh mục', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  const SizedBox(height: 24),
                  _buildInputLabel('Tên danh mục'),
                  TextField(controller: nameCtrl, decoration: _inputDeco('Vd: Bảng điểm')),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel('Phòng ban xử lý'),
                          DropdownButtonFormField<String>(initialValue: selectedDept, decoration: _inputDeco(''), items: const [DropdownMenuItem(value: 'ctsv', child: Text('Phòng CTSV')), DropdownMenuItem(value: 'khoa', child: Text('VP Khoa'))], onChanged: (v) => setDialogState(() => selectedDept = v!)),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel('Hạn xử lý (SLA)'),
                          DropdownButtonFormField<String>(initialValue: selectedSla, decoration: _inputDeco(''), items: slaOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setDialogState(() => selectedSla = v!)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputLabel('Mô tả quy trình'),
                  TextField(controller: descCtrl, maxLines: 3, decoration: _inputDeco('Hướng dẫn sinh viên...')),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: AppColors.gray500))), const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty) return;
                          final data = {'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim(), 'department': selectedDept, 'sla': selectedSla, 'isActive': isEditing ? category['isActive'] : true};
                          try {
                            if (isEditing) {
                              await Supabase.instance.client.from('request_categories').update(data).eq('id', category['id']);
                            } else {
                              await Supabase.instance.client.from('request_categories').insert(data);
                            }
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            _fetchCategories();
                            GlassToast.show(context, 'Lưu thành công!');
                            await DbService().logAudit(isEditing ? 'UPDATE' : 'CREATE', 'Danh mục Yêu cầu', 'Đã ${isEditing ? 'sửa' : 'tạo mới'} danh mục: ${nameCtrl.text.trim()}');
                          } catch (e) { 
                            if (!context.mounted) return;
                            GlassToast.show(context, 'Lỗi lưu dữ liệu', isError: true); 
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildInputLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)));
  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: AppColors.gray100, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A))));

  @override
  Widget build(BuildContext context) {
    final filtered = _categories.where((e) => e['name'].toString().toLowerCase().contains(_searchTerm.toLowerCase())).toList();

    return _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))) : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          // FIX UI BẰNG WRAP CHO HEADER
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 16, runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Quản lý Danh mục', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gray900)), SizedBox(height: 6), Text('Kiểm soát các loại yêu cầu từ sinh viên có thể tạo.', style: TextStyle(color: AppColors.gray500))]),
                Wrap(
                  spacing: 16, runSpacing: 16,
                  children: [
                    SizedBox(width: 280, child: TextField(onChanged: (val) => setState(() => _searchTerm = val), decoration: _inputDeco('Tìm kiếm danh mục...').copyWith(prefixIcon: const Icon(Icons.search_rounded), fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200))))),
                    ElevatedButton.icon(onPressed: () => _showAddEditDialog(), icon: const Icon(Icons.add_rounded, color: Colors.white), label: const Text('Thêm loại đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))
                  ],
                )
              ],
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty 
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.category_outlined, size: 80, color: AppColors.gray200), const SizedBox(height: 16), const Text('Không tìm thấy danh mục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.gray500))]))
            // FIX UI BẰNG CÁCH BỌC CUỘN NGANG CHO LISTVIEW
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1000,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32), itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final cat = filtered[index];
                      final isActive = cat['isActive'] ?? false;
                      final dept = cat['department'] == 'ctsv' ? 'Phòng CTSV' : 'VP Khoa';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gray200)),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (isActive ? const Color(0xFF1E3A8A) : AppColors.gray500).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.description_rounded, color: isActive ? const Color(0xFF1E3A8A) : AppColors.gray500)),
                            const SizedBox(width: 20),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(width: 12), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(dept, style: const TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold)))]),
                              const SizedBox(height: 6), Text(cat['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.gray500, fontSize: 13))
                            ])),
                            Column(children: [const Text('Hạn xử lý', style: TextStyle(color: AppColors.gray500, fontSize: 11)), const SizedBox(height: 4), Text(cat['sla'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))]),
                            const SizedBox(width: 32),
                            Switch(value: isActive, activeThumbColor: const Color(0xFF1E3A8A), onChanged: (v) => _toggleStatus(cat['id'], !v)),
                            IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.gray500), onPressed: () => _showAddEditDialog(cat)),
                            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), onPressed: () => _deleteCategory(cat['id'])),
                          ],
                        ),
                      );
                    }
                  ),
                ),
              ),
        )
      ],
    );
  }
}