// lib/ui/screens/admin/admin_audit_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../widgets/glass_toast.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String _searchTerm = '';
  String _filterType = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final response = await Supabase.instance.client.from('audit_logs').select().order('created_at', ascending: false).limit(200); // Kéo 200 hành động mới nhất
      if (mounted) setState(() { _logs = List<Map<String, dynamic>>.from(response); _isLoading = false; });
    } catch (e) {
      debugPrint('Lỗi tải nhật ký Audit: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        GlassToast.show(context, 'Lỗi tải dữ liệu: Vui lòng kiểm tra lại quyền Database!', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _logs.where((log) {
      final type = (log['action_type'] ?? '').toString().toUpperCase();
      final name = (log['actor_name'] ?? '').toString().toLowerCase();
      final target = (log['target_name'] ?? '').toString().toLowerCase();
      
      final matchesFilter = _filterType == 'ALL' || type == _filterType;
      final matchesSearch = name.contains(_searchTerm.toLowerCase()) || target.contains(_searchTerm.toLowerCase());
      
      return matchesFilter && matchesSearch;
    }).toList();

    return _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primarySV)) : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Wrap(
            spacing: 16, runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [Text('Nhật ký Hoạt động', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gray900)), SizedBox(height: 6), Text('Giám sát mọi thao tác tạo, sửa, xóa trên hệ thống.', style: TextStyle(color: AppColors.gray500))]
              ),
              Wrap(
                spacing: 16, runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(onPressed: _fetchLogs, icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18), label: const Text('Làm mới', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterType,
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Mọi hành động')),
                          DropdownMenuItem(value: 'CREATE', child: Text('🟢 Tạo mới (CREATE)')),
                          DropdownMenuItem(value: 'UPDATE', child: Text('🟠 Chỉnh sửa (UPDATE)')),
                          DropdownMenuItem(value: 'DELETE', child: Text('🔴 Xóa (DELETE)')),
                          DropdownMenuItem(value: 'LOGIN', child: Text('🔵 Đăng nhập (LOGIN)')),
                        ],
                        onChanged: (val) => setState(() => _filterType = val!),
                      ),
                    ),
                  ),
                  SizedBox(width: 250, child: TextField(onChanged: (val) => setState(() => _searchTerm = val), decoration: InputDecoration(hintText: 'Tìm người thực hiện...', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A)))))),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: filteredLogs.isEmpty
            ? const Center(child: Text('Không có dữ liệu nhật ký.', style: TextStyle(color: AppColors.gray500)))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: constraints.maxWidth > 1000 ? constraints.maxWidth : 1000, 
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 32), itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          final date = DateTime.parse(log['created_at'] ?? DateTime.now().toIso8601String()).toLocal();
                          final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}";
                          final action = (log['action_type'] ?? '').toString().toUpperCase();

                          Color aColor; IconData aIcon; String aText;
                          if(action == 'CREATE') { aColor = AppColors.success; aIcon = Icons.add_circle_rounded; aText = 'TẠO MỚI'; }
                          else if(action == 'DELETE') { aColor = AppColors.danger; aIcon = Icons.delete_forever_rounded; aText = 'XÓA BỎ'; }
                          else if(action == 'UPDATE') { aColor = AppColors.warning; aIcon = Icons.edit_rounded; aText = 'CẬP NHẬT'; }
                          else if(action == 'LOGIN') { aColor = Colors.blue; aIcon = Icons.login_rounded; aText = 'ĐĂNG NHẬP'; }
                          else { aColor = AppColors.gray500; aIcon = Icons.settings_rounded; aText = 'HỆ THỐNG'; }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gray200)),
                            child: Row(
                              children: [
                                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: aColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(aIcon, color: aColor, size: 24)),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [Text(log['actor_name'] ?? 'Ẩn danh', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(width: 8), Text('(${log['actor_email'] ?? ''})', style: const TextStyle(color: AppColors.gray500, fontSize: 12))]),
                                      const SizedBox(height: 6),
                                      Text(log['details'] ?? '', style: const TextStyle(color: AppColors.gray500, fontSize: 14)),
                                    ]
                                  )
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: aColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(aText, style: TextStyle(color: aColor, fontSize: 11, fontWeight: FontWeight.bold))),
                                      const SizedBox(height: 8),
                                      Text(timeStr, style: const TextStyle(color: AppColors.gray500, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        }
                      ),
                    ),
                  );
                }
              ),
        )
      ],
    );
  }
}