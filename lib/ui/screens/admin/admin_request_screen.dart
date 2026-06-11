// lib/ui/screens/admin/admin_request_screen.dart
import 'package:huit_student_request_app/services/web_exporter_stub.dart'
    if (dart.library.html) 'package:huit_student_request_app/services/web_exporter_web.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/services/db_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../widgets/glass_toast.dart';

class AdminRequestScreen extends StatefulWidget {
  const AdminRequestScreen({super.key});

  @override
  State<AdminRequestScreen> createState() => _AdminRequestScreenState();
}

class _AdminRequestScreenState extends State<AdminRequestScreen> {
  List<Map<String, dynamic>> _requests = [];
  final Map<String, String> _staffCache = {}; 
  bool _isLoading = true;

  // BIẾN CHO BỘ LỌC VÀ TÌM KIẾM
  String _searchTerm = '';
  String _selectedFilter = 'all';

  // VŨ KHÍ MỚI: QUẢN LÝ CHỌN NHIỀU (BULK ACTIONS)
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final response = await Supabase.instance.client.from('requests').select().order('createdAt', ascending: false);
      if (mounted) setState(() { _requests = List<Map<String, dynamic>>.from(response); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _getStaffName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'Chưa có người xử lý';
    if (_staffCache.containsKey(uid)) return _staffCache[uid]!;
    try {
      final res = await Supabase.instance.client.from('users').select('name').eq('uid', uid).maybeSingle();
      final name = res?['name'] ?? 'Không rõ';
      _staffCache[uid] = name;
      return name;
    } catch (e) { return 'Không rõ'; }
  }

  // ─── HÀM XÓA HÀNG LOẠT ───
  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hàng loạt', style: TextStyle(color: AppColors.danger)), 
        content: Text('Bạn sắp xóa vĩnh viễn ${_selectedIds.length} yêu cầu. Hành động này không thể hoàn tác!'), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), 
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('Tiêu hủy', style: TextStyle(color: Colors.white)))
        ]
      )
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('requests').delete().inFilter('id', _selectedIds.toList());
        await DbService().logAudit('DELETE', 'Yêu cầu sinh viên', 'Đã xóa hàng loạt ${_selectedIds.length} yêu cầu khỏi hệ thống.');
        if(!mounted) return;
        GlassToast.show(context, 'Đã dọn dẹp thành công ${_selectedIds.length} yêu cầu!');
        setState(() { _isSelectionMode = false; _selectedIds.clear(); });
        _fetchRequests();
      } catch (e) { 
        if(!mounted) return;
        GlassToast.show(context, 'Lỗi xóa hàng loạt', isError: true); 
      }
    }
  }

  // ─── HÀM XUẤT BÁO CÁO CSV ───
  void _exportCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      GlassToast.show(context, 'Không có dữ liệu để xuất!', isError: true);
      return;
    }
    
    String csv = "Mã Đơn,Tên Sinh Viên,MSSV,Loại Đơn,Lý Do,Trạng thái,Ngày tạo\n";
    for (var req in data) {
      final status = req['status'] == 'approved' ? 'Da Duyet' : (req['status'] == 'rejected' ? 'Tu Choi' : 'Cho Xu Ly');
      final reason = (req['reason'] ?? '').toString().replaceAll(',', ' ');
      csv += "${req['id']},${req['studentName']},${req['studentId']},${req['categoryName']},$reason,$status,${req['createdAt']}\n";
    }

    // GỌI HÀM BIÊN DỊCH
    WebExporter.downloadCSVWeb(csv, "Bao_Cao_Don_Tu_HDPE", context);

    GlassToast.show(context, 'Đã xử lý tiến trình trích xuất file Excel!');
  }

  Future<void> _deleteRequest(String reqId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(title: const Text('Xóa Yêu cầu', style: TextStyle(color: AppColors.danger)), content: const Text('Hành động này sẽ xóa vĩnh viễn yêu cầu khỏi cơ sở dữ liệu. Đồng ý?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('Tiêu hủy'))])
    );
    if (confirm == true) {
      try {
        await Supabase.instance.client.from('requests').delete().eq('id', reqId);
        await DbService().logAudit('DELETE', 'Yêu cầu sinh viên', 'Đã xóa vĩnh viễn yêu cầu có mã ID: $reqId');
        if(!mounted) return;
        GlassToast.show(context, 'Đã xóa yêu cầu vĩnh viễn!');
        _fetchRequests();
      } catch (e) { 
        if(!mounted) return;
        GlassToast.show(context, 'Lỗi xóa', isError: true); 
      }
    }
  }

  void _showRequestDetailsDialog(BuildContext context, Map<String, dynamic> req, Color statusColor, Color statusBg, String statusText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray200))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chi tiết yêu cầu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                      IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.gray500, size: 28), onPressed: () => Navigator.pop(context)) 
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)), child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold))),
                            Text('Mã đơn: ${req['id']}', style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Thông tin Sinh viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)), const SizedBox(height: 12),
                        Row(children: [const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.gray500), const SizedBox(width: 12), Expanded(child: Text('${req['studentName']} - ${req['studentId']}', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis))]),
                        
                        const SizedBox(height: 24), const Divider(), const SizedBox(height: 24),
                        
                        const Text('Nội dung Yêu cầu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)), const SizedBox(height: 12),
                        Row(children: [const Icon(Icons.file_copy_outlined, size: 20, color: AppColors.gray500), const SizedBox(width: 12), Expanded(child: Text(req['categoryName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis))]),
                        const SizedBox(height: 16),
                        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(12)), child: Text(req['reason'] ?? 'Không có lý do', style: const TextStyle(color: AppColors.gray900, height: 1.5))),
                        
                        const SizedBox(height: 24),
                        const Text('Minh chứng của Sinh viên:', style: TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
                        if (req['attachmentUrls'] != null && (req['attachmentUrls'] as List).isNotEmpty)
                          ...List.generate((req['attachmentUrls'] as List).length, (i) {
                            return InkWell(
                              onTap: () => launchUrl(Uri.parse((req['attachmentUrls'] as List)[i].toString())),
                              child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.link_rounded, color: Colors.blue), SizedBox(width: 12), Text('Xem tệp đính kèm', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))])),
                            );
                          })
                        else const Text('Không có tệp', style: TextStyle(color: AppColors.gray500, fontStyle: FontStyle.italic)),

                        const SizedBox(height: 24), const Divider(), const SizedBox(height: 24),

                        const Text('Kết quả xử lý (Từ Giáo vụ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)), const SizedBox(height: 12),
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req['note'] ?? 'Chưa có ghi chú', style: TextStyle(color: statusColor, fontStyle: FontStyle.italic)),
                              ...(() {
                                List<dynamic> uploadedStaffFiles = [];
                                if (req['attachedFiles'] is List) {
                                  uploadedStaffFiles = req['attachedFiles'];
                                } else if (req['attachedFiles'] is String && req['attachedFiles'].toString().trim().isNotEmpty) {
                                  try {
                                    uploadedStaffFiles = jsonDecode(req['attachedFiles']);
                                  } catch (_) {
                                    final str = req['attachedFiles'].toString().trim();
                                    if (str.startsWith('{') && str.endsWith('}')) {
                                      uploadedStaffFiles = str.substring(1, str.length - 1).split(',').map((e) => e.replaceAll('"', '').trim()).where((e) => e.isNotEmpty).toList();
                                    } else if (str.startsWith('http')) {
                                      uploadedStaffFiles = [str];
                                    }
                                  }
                                }
                                if (uploadedStaffFiles.isEmpty) return <Widget>[];
                                return [
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () => launchUrl(Uri.parse(uploadedStaffFiles[0].toString())),
                                  child: const Text('Mở file kết quả của Giáo vụ 🔗', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                )
                                ];
                              })()
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // UPDATE: TÌM KIẾM THEO MÃ ĐƠN (Thêm req['id'])
    final filteredReqs = _requests.where((req) {
      final status = (req['status'] ?? 'pending').toString().toLowerCase();
      final name = (req['studentName'] ?? '').toString().toLowerCase();
      final sid = (req['studentId'] ?? '').toString().toLowerCase();
      final reqId = (req['id'] ?? '').toString().toLowerCase(); // Lấy ID
      
      final matchesFilter = _selectedFilter == 'all' || status == _selectedFilter;
      final matchesSearch = name.contains(_searchTerm.toLowerCase()) || sid.contains(_searchTerm.toLowerCase()) || reqId.contains(_searchTerm.toLowerCase());
      
      return matchesFilter && matchesSearch;
    }).toList();

    return _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))) : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 16, runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Giám sát Đơn từ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gray900)), SizedBox(height: 6), Text('Quản trị viên xem xét tình trạng và tiêu hủy đơn nếu cần.', style: TextStyle(color: AppColors.gray500))]),
              
              Wrap(
                spacing: 16, runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_isSelectionMode) ...[
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(12)), child: Text('Đã chọn ${_selectedIds.length} đơn', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger))),
                    ElevatedButton.icon(onPressed: _bulkDelete, icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 18), label: const Text('Xóa hàng loạt', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger)),
                    OutlinedButton(onPressed: () => setState(() { _isSelectionMode = false; _selectedIds.clear(); }), child: const Text('Hủy', style: TextStyle(color: AppColors.gray500))),
                  ] else ...[
                    OutlinedButton.icon(onPressed: () => setState(() => _isSelectionMode = true), icon: const Icon(Icons.checklist_rtl_rounded, color: Color(0xFF1E3A8A), size: 18), label: const Text('Chọn nhiều', style: TextStyle(color: Color(0xFF1E3A8A)))),
                    ElevatedButton.icon(onPressed: () => _exportCSV(filteredReqs), icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18), label: const Text('Xuất CSV', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                            DropdownMenuItem(value: 'pending', child: Text('Chờ tiếp nhận')),
                            DropdownMenuItem(value: 'processing', child: Text('Đang xử lý')),
                            DropdownMenuItem(value: 'approved', child: Text('Đã duyệt / Hoàn thành')),
                            DropdownMenuItem(value: 'rejected', child: Text('Từ chối / Hủy')),
                          ],
                          onChanged: (val) => setState(() => _selectedFilter = val!),
                        ),
                      ),
                    ),
                    SizedBox(width: 250, child: TextField(onChanged: (val) => setState(() => _searchTerm = val), decoration: InputDecoration(hintText: 'Tìm SV hoặc Mã đơn...', prefixIcon: const Icon(Icons.search_rounded), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A)))))),
                  ]
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: filteredReqs.isEmpty
            ? const Center(child: Text('Không tìm thấy đơn yêu cầu nào.', style: TextStyle(color: AppColors.gray500)))
            // ─── FIX LỖI LỆCH UI BẰNG LAYOUT BUILDER ───
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      // Bí kíp: Nếu màn hình rộng hơn 1150 thì cho giãn full, nếu hẹp thì khóa lại để cuộn ngang. Không bao giờ bị lệch trái nữa!
                      width: constraints.maxWidth > 1150 ? constraints.maxWidth : 1150, 
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24), itemCount: filteredReqs.length,
                        itemBuilder: (context, index) {
                          final req = filteredReqs[index];
                          final status = (req['status'] ?? 'pending').toString().toLowerCase();
                          final date = DateTime.parse(req['createdAt'] ?? DateTime.now().toIso8601String()).toLocal();
                          
                          final shortId = req['id'].toString().substring(req['id'].toString().length - 4).toUpperCase();
                          String prefix = 'RQ';
                          if ((req['categoryName'] ?? '').isNotEmpty) { prefix = req['categoryName'].split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join(''); }
                          final formattedId = '#$prefix-${date.day}${date.month}-$shortId';
                          final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}";

                          Color sColor; String sText;
                          if(status == 'approved' || status == 'completed') { sColor = AppColors.success; sText = 'Hoàn thành'; }
                          else if(status == 'rejected') { sColor = AppColors.danger; sText = 'Từ chối / Hủy'; }
                          else if(status == 'processing') { sColor = AppColors.warning; sText = 'Đang xử lý'; }
                          else { sColor = Colors.blue; sText = 'Chờ nhận'; }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: _selectedIds.contains(req['id'].toString()) ? AppColors.dangerLight : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _selectedIds.contains(req['id'].toString()) ? AppColors.danger : AppColors.gray200)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center, // FIX LỆCH VERTICAL
                              children: [
                                if (_isSelectionMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Checkbox(value: _selectedIds.contains(req['id'].toString()), activeColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), onChanged: (val) { setState(() { if (val == true) { _selectedIds.add(req['id'].toString()); } else { _selectedIds.remove(req['id'].toString()); } }); })
                                  ),
                                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: sColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.assignment_rounded, color: sColor, size: 24)),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [Text(req['categoryName'] ?? 'Đơn', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(width: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: sColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(sText, style: TextStyle(color: sColor, fontSize: 11, fontWeight: FontWeight.bold)))]),
                                      const SizedBox(height: 6),
                                      Text('$formattedId • Sinh viên: ${req['studentName']} (${req['studentId']})', style: const TextStyle(color: AppColors.gray900, fontSize: 13, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(req['reason'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.gray500, fontSize: 13, fontStyle: FontStyle.italic)),
                                      const SizedBox(height: 4),
                                      Text(timeStr, style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
                                    ]
                                  )
                                ),
                                Expanded(
                                  flex: 1,
                                  child: FutureBuilder<String>(
                                    future: _getStaffName(req['staffUid']),
                                    builder: (context, snapshot) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Giáo vụ phụ trách:', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                                          const SizedBox(height: 4),
                                          Text(snapshot.data ?? '...', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                                        ],
                                      );
                                    }
                                  ),
                                ),
                                IconButton(icon: const Icon(Icons.remove_red_eye_rounded, color: AppColors.gray500), tooltip: 'Xem chi tiết', onPressed: _isSelectionMode ? null : () => _showRequestDetailsDialog(context, req, sColor, sColor.withValues(alpha: 0.1), sText)),
                                const SizedBox(width: 8),
                                IconButton(icon: Icon(Icons.delete_forever_rounded, color: _isSelectionMode ? AppColors.gray300 : AppColors.danger), tooltip: 'Xóa vĩnh viễn', onPressed: _isSelectionMode ? null : () => _deleteRequest(req['id'].toString())),
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