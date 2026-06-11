// lib/ui/screens/staff/staff_request_screen.dart
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/services/db_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../../core/theme.dart';
import '../../widgets/glass_toast.dart';
import 'package:provider/provider.dart';
import '../../../state/auth_provider.dart';
import 'package:file_picker/file_picker.dart';

class StaffRequestScreen extends StatefulWidget {
  const StaffRequestScreen({super.key});

  @override
  State<StaffRequestScreen> createState() => _StaffRequestScreenState();
}

class _StaffRequestScreenState extends State<StaffRequestScreen> with SingleTickerProviderStateMixin {
  String _activeTab = 'all';
  String _searchTerm = '';
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fetchRequests();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    try {
      final response = await Supabase.instance.client.from('requests').select().order('createdAt', ascending: false);
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
        _animController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách đơn từ Supabase: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _requests.where((req) {
      final status = (req['status'] ?? 'pending').toString().toLowerCase();
      
      bool matchesTab = false;
      if (_activeTab == 'all') matchesTab = true;
      else if (_activeTab == 'approved') matchesTab = (status == 'approved' || status == 'completed');
      else matchesTab = (status == _activeTab);

      // UPDATE: TÌM KIẾM THEO MÃ ĐƠN 
      final name = (req['studentName'] ?? '').toString().toLowerCase();
      final sid = (req['studentId'] ?? '').toString().toLowerCase();
      final reqId = (req['id'] ?? '').toString().toLowerCase();
      
      // Tính toán mã đơn (VD: #RQ-106-ABCD)
      final date = DateTime.parse(req['createdAt'] ?? DateTime.now().toIso8601String()).toLocal();
      final shortId = req['id'].toString().length >= 4 ? req['id'].toString().substring(req['id'].toString().length - 4).toUpperCase() : req['id'].toString().toUpperCase();
      String prefix = 'RQ';
      if ((req['categoryName'] ?? '').toString().isNotEmpty) { 
        prefix = req['categoryName'].split(' ').map((word) => word.toString().isNotEmpty ? word.toString()[0].toUpperCase() : '').join(''); 
      }
      final formattedId = '#$prefix-${date.day}${date.month}-$shortId'.toLowerCase();

      final matchesSearch = name.contains(_searchTerm.toLowerCase()) || 
                            sid.contains(_searchTerm.toLowerCase()) || 
                            reqId.contains(_searchTerm.toLowerCase()) ||
                            formattedId.contains(_searchTerm.toLowerCase());
                            
      return matchesTab && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primarySV))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
                child: Wrap(
                  spacing: 16, runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quản lý Đơn từ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gray900, letterSpacing: -0.5)),
                        SizedBox(height: 6),
                        Text('Quản lý và xét duyệt các yêu cầu học vụ của sinh viên', style: TextStyle(fontSize: 15, color: AppColors.gray500, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    SizedBox(
                      width: 320,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchTerm = val),
                        decoration: InputDecoration(
                          hintText: 'Tìm MSSV, tên, Mã đơn...', prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray500), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySV, width: 1.5)),
                        ),
                      ),
                    )
                  ],
                ),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    _buildTab('all', 'Tất cả Đơn', _requests.length),
                    _buildTab('pending', 'Chờ xử lý', _requests.where((e) => e['status'] == 'pending').length),
                    _buildTab('processing', 'Đang xử lý', _requests.where((e) => e['status'] == 'processing').length),
                    _buildTab('approved', 'Đã duyệt', _requests.where((e) => e['status'] == 'approved' || e['status'] == 'completed').length),
                    _buildTab('rejected', 'Từ chối', _requests.where((e) => e['status'] == 'rejected').length),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: filteredRequests.isEmpty 
                  ? const Center(child: Text('Không tìm thấy đơn nào khớp.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray500)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420, mainAxisExtent: 260, crossAxisSpacing: 24, mainAxisSpacing: 24
                      ),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        final req = filteredRequests[index];
                        return _StaggeredCard(
                          index: index, controller: _animController,
                          child: _RequestCard(request: req, onRefresh: _fetchRequests),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }

  Widget _buildTab(String id, String label, int count) {
    final isActive = _activeTab == id;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _activeTab = id),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: isActive ? AppColors.primarySV : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? AppColors.primarySV : AppColors.gray200), boxShadow: isActive ? [BoxShadow(color: AppColors.primarySV.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : []),
          child: Row(
            children: [
              Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.gray500, fontWeight: isActive ? FontWeight.bold : FontWeight.w600)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.2) : AppColors.gray100, borderRadius: BorderRadius.circular(20)), child: Text(count.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.white : AppColors.gray500))),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggeredCard extends StatelessWidget {
  final int index; final AnimationController controller; final Widget child;
  const _StaggeredCard({required this.index, required this.controller, required this.child});
  @override
  Widget build(BuildContext context) {
    final delay = (index * 0.05).clamp(0.0, 1.0);
    final animation = CurvedAnimation(parent: controller, curve: Interval(delay, 1.0, curve: Curves.easeOutCubic));
    return AnimatedBuilder(animation: animation, builder: (context, child) => Transform.translate(offset: Offset(0, 40 * (1 - animation.value)), child: Opacity(opacity: animation.value, child: child)), child: child);
  }
}

class _RequestCard extends StatefulWidget {
  final Map<String, dynamic> request; final VoidCallback onRefresh;
  const _RequestCard({required this.request, required this.onRefresh});
  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _isHovered = false;

  Future<void> _autoUpdateToProcessing(String reqId) async {
    try {
      await Supabase.instance.client.from('requests').update({'status': 'processing', 'processedAt': DateTime.now().toUtc().toIso8601String()}).eq('id', reqId);
    } catch (e) {
      debugPrint('Lỗi auto-processing: $e');
    }
  }

  void _showRequestDetailsDialog(BuildContext context, Map<String, dynamic> req, Color statusColor, Color statusBg, String statusText) {
    if (req['status'] == 'pending') {
      _autoUpdateToProcessing(req['id']);
      req['status'] = 'processing'; 
      statusColor = const Color(0xFF3B82F6); statusBg = const Color(0xFFDBEAFE); statusText = 'Đang xử lý';
    }

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        final feedbackController = TextEditingController(text: req['note'] ?? '');
        bool isProcessingForm = false;
        List<PlatformFile> localStaffFiles = [];

        return Dialog(
          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), insetPadding: const EdgeInsets.all(24), elevation: 10,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 950, maxHeight: 850),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final currentStatus = req['status'] ?? 'pending';
                final isEditable = currentStatus == 'pending' || currentStatus == 'processing';
                final screenWidthDialog = MediaQuery.of(context).size.width; 

                // Lấy mã đơn chuẩn hóa để hiển thị
                final date = DateTime.parse(req['createdAt'] ?? DateTime.now().toIso8601String()).toLocal();
                final shortId = req['id'].toString().substring(req['id'].toString().length - 4).toUpperCase();
                String prefix = 'RQ';
                if ((req['categoryName'] ?? '').isNotEmpty) { prefix = req['categoryName'].split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join(''); }
                final formattedId = '#$prefix-${date.day}${date.month}-$shortId';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HEADER DIALOG
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), 
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray200))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Hồ sơ Xử lý Đơn từ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gray900)), const SizedBox(height: 4), Text('Mã hệ thống: $formattedId', style: const TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold, fontSize: 13))]),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.gray500, size: 28), 
                            tooltip: 'Đóng cửa sổ',
                            onPressed: () => Navigator.pop(context)
                          ) 
                        ],
                      ),
                    ),

                    // BODY DIALOG
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Flex(
                          direction: screenWidthDialog < 800 ? Axis.vertical : Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── CỘT TRÁI: THÔNG TIN SINH VIÊN & ĐƠN TỪ ───
                            Expanded(
                              flex: screenWidthDialog < 800 ? 0 : 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.gray100.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gray200)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('👤 Thông tin Sinh viên', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)), const SizedBox(height: 16),
                                        _buildInfoRow(Icons.badge_outlined, 'MSSV:', req['studentId'] ?? ''),
                                        _buildInfoRow(Icons.person_outline_rounded, 'Họ và tên:', req['studentName'] ?? ''),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  const Text('📄 Nội dung Yêu cầu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)), const SizedBox(height: 12),
                                  _buildInfoRow(Icons.file_copy_outlined, 'Loại đơn:', req['categoryName'] ?? ''),
                                  if (req['subjectCode'] != null && req['subjectCode'].toString().isNotEmpty) _buildInfoRow(Icons.book_outlined, 'Môn học:', req['subjectCode']),
                                  
                                  const SizedBox(height: 16),
                                  const Text('Lý do / Trình bày chi tiết:', style: TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
                                  Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200)), child: Text(req['reason'] ?? '', style: const TextStyle(color: AppColors.gray900, height: 1.5))),
                                  
                                  const SizedBox(height: 24),
                                  const Text('📎 Minh chứng đính kèm (SV nộp):', style: TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
                                  if (req['attachmentUrls'] != null && (req['attachmentUrls'] as List).isNotEmpty)
                                    Wrap(
                                      spacing: 12, runSpacing: 12,
                                      children: List.generate((req['attachmentUrls'] as List).length, (i) {
                                        final url = (req['attachmentUrls'] as List)[i].toString();
                                        return InkWell(
                                          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication), // FIX LỖI 3: Dùng externalApplication để xem PDF/Word
                                          child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.primarySV.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12), color: AppColors.primarySV.withValues(alpha: 0.05)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.download_rounded, color: AppColors.primarySV, size: 18), const SizedBox(width: 8), Text('Tài liệu ${i + 1}', style: const TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold))])),
                                        );
                                      })
                                    )
                                  else const Text('Không có tệp đính kèm', style: TextStyle(color: AppColors.gray500, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                            
                            if (screenWidthDialog >= 800) const SizedBox(width: 32),
                            if (screenWidthDialog < 800) const SizedBox(height: 32),
                            
                            // ─── CỘT PHẢI: FORM XỬ LÝ CỦA GIÁO VỤ ───
                            Expanded(
                              flex: screenWidthDialog < 800 ? 0 : 4,
                              child: Container(
                                padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primarySV.withValues(alpha: 0.2)), boxShadow: [BoxShadow(color: AppColors.primarySV.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))]),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isEditable) ...[
                                      const Row(children: [Icon(Icons.edit_document, color: AppColors.primarySV), SizedBox(width: 8), Text('Không gian Xử lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primarySV))]),
                                      const SizedBox(height: 24),
                                      const Text('Ghi chú / Phản hồi cho SV (*):', style: TextStyle(fontSize: 13, color: AppColors.gray900, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
                                      TextField(controller: feedbackController, maxLines: 5, decoration: InputDecoration(hintText: 'Nhập hướng dẫn bổ sung hồ sơ, lý do từ chối hoặc kết quả xử lý...', filled: true, fillColor: AppColors.gray100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySV)))),
                                      
                                      const SizedBox(height: 24),
                                      const Text('Tài liệu trả về cho SV (Tùy chọn):', style: TextStyle(fontSize: 13, color: AppColors.gray900, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
                                      
                                      // UPLOAD NHIỀU FILE & CÓ NÚT XÓA (CHIP)
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          // Sử dụng chuẩn platform.pickFiles kết hợp withData để ép Web nạp dữ liệu tệp
                                          FilePickerResult? result = await FilePicker.pickFiles(
                                            allowMultiple: true, 
                                            withData: true
                                          );
                                          if (result != null && context.mounted) {
                                            setDialogState(() {
                                              for (var file in result.files) {
                                                if (!localStaffFiles.any((f) => f.name == file.name)) {
                                                  localStaffFiles.add(file);
                                                }
                                              }
                                            });
                                          }
                                        },
                                        icon: const Icon(Icons.cloud_upload_rounded), label: const Text('Chọn File đính kèm'),
                                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size.fromHeight(45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: const BorderSide(color: AppColors.primarySV)),
                                      ),       
                                      
                                      if (localStaffFiles.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8, runSpacing: 8,
                                          children: localStaffFiles.map((file) {
                                            return Chip(
                                              label: Text(file.name, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              deleteIcon: const Icon(Icons.cancel, size: 16, color: AppColors.danger),
                                              onDeleted: () => setDialogState(() => localStaffFiles.remove(file)),
                                              backgroundColor: AppColors.gray100, side: BorderSide.none,
                                            );
                                          }).toList(),
                                        )
                                      ],
                                      
                                      const SizedBox(height: 40),
                                      if (isProcessingForm) const Center(child: CircularProgressIndicator(color: AppColors.primarySV))
                                      else Row(
                                        children: [
                                          Expanded(child: ElevatedButton.icon(onPressed: () => _updateStatus(req, formattedId, 'rejected', feedbackController.text, localStaffFiles, setDialogState, () => isProcessingForm = true), icon: const Icon(Icons.cancel_outlined, color: Colors.white), label: const Text('Từ chối', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: AppColors.danger, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                                          const SizedBox(width: 12),
                                          Expanded(child: ElevatedButton.icon(onPressed: () => _updateStatus(req, formattedId, 'approved', feedbackController.text, localStaffFiles, setDialogState, () => isProcessingForm = true), icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white), label: const Text('Duyệt Đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                                        ],
                                      )
                                    ] else ...[
                                      Row(children: [Icon(Icons.history_rounded, color: statusColor, size: 24), const SizedBox(width: 8), Text('Kết quả Xử lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor))]),
                                      const SizedBox(height: 20),
                                      const Text('Ghi chú của Cán bộ:', style: TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
                                      Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: statusBg.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Text(req['note'] ?? 'Không có ghi chú.', style: TextStyle(color: statusColor, fontStyle: FontStyle.italic))),
                                      
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
                                        const SizedBox(height: 20),
                                        const Text('File kết quả đính kèm:', style: TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 12, runSpacing: 12,
                                          children: List.generate(uploadedStaffFiles.length, (i) {
                                            final url = uploadedStaffFiles[i].toString();
                                            return InkWell(
                                              onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                                              child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: statusColor.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12), color: statusBg), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.file_present_rounded, color: statusColor, size: 18), const SizedBox(width: 8), Text('Tài liệu trả về ${i + 1}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))])),
                                            );
                                          })
                                        )
                                        ];
                                      })(),
                                      
                                      const SizedBox(height: 32),
                                      SizedBox(
                                        width: double.infinity, height: 48,
                                        child: OutlinedButton.icon(
                                          onPressed: () => Navigator.pop(context),
                                          icon: const Icon(Icons.close_rounded, color: AppColors.gray500),
                                          label: const Text('Đóng biểu mẫu', style: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.gray200),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                          ),
                                        ),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        );
      }
    );
  }

  // Cập nhật hàm updateStatus để nhận thêm formattedId
  Future<void> _updateStatus(Map<String, dynamic> req, String formattedId, String newStatus, String note, List<PlatformFile> localFiles, Function setDialogState, Function setLoading) async {
    if (note.trim().isEmpty) { GlassToast.show(context, 'Vui lòng nhập ghi chú phản hồi cho sinh viên!', isError: true); return; }
    setDialogState(() => setLoading());
    
    try {
      final staffUid = context.read<AuthProvider>().currentUser?.uid;
      List<String> uploadedUrls = [];

      for (PlatformFile file in localFiles) {
        final path = 'staff_replies/${staffUid ?? 'staff'}_${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final Uint8List? fileBytes = file.bytes;

        if (fileBytes != null) {
          // 🌐 Trường hợp 1: Tải lên dạng Bytes qua hàm uploadBinary chuẩn của thư viện
          await Supabase.instance.client.storage.from('attachments').uploadBinary(
            path, 
            fileBytes,
            fileOptions: const FileOptions(upsert: true), // Ghi đè file nếu trùng tên chống lỗi kẹt file
          );
          final url = Supabase.instance.client.storage.from('attachments').getPublicUrl(path);
          uploadedUrls.add(url);
        } else if (!kIsWeb && file.path != null) {
          // 💻 Trường hợp 2: Tải lên dạng Path (Chạy trên Windows/Mobile app khi bytes trống)
          final ioFile = io.File(file.path!);
          await Supabase.instance.client.storage.from('attachments').upload(path, ioFile);
          final url = Supabase.instance.client.storage.from('attachments').getPublicUrl(path);
          uploadedUrls.add(url);
        } else {
          debugPrint("Cảnh báo: Không thể bóc tách luồng dữ liệu của file: ${file.name}");
        }
      }

      final updateData = {
        'status': newStatus, 'note': note, 'staffUid': staffUid, 'attachedFiles': uploadedUrls, 'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      if (newStatus == 'approved') updateData['completedAt'] = DateTime.now().toUtc().toIso8601String();
      if (newStatus == 'rejected') updateData['rejectedAt'] = DateTime.now().toUtc().toIso8601String();

      await Supabase.instance.client.from('requests').update(updateData).eq('id', req['id']);
      
      await Supabase.instance.client.from('notifications').insert({
        'student_uid': req['studentUid'],
        'title': newStatus == 'approved' ? '✅ Đơn $formattedId đã được xử lý' : '❌ Đơn $formattedId bị từ chối',
        'body': 'Đơn "${req['categoryName']}" của bạn đã có kết quả. Phản hồi: "$note". Nhấn để xem chi tiết.',
        'request_id': req['id'], 'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String()
      });

      await DbService().logAudit('UPDATE', 'Xử lý Đơn', 'Đã chuyển trạng thái đơn ${req['id']} thành: $newStatus');

      if (mounted) {
        Navigator.pop(context); GlassToast.show(context, 'Xử lý đơn thành công!'); widget.onRefresh();
      }
    } catch (e) {
      if (mounted) GlassToast.show(context, 'Lỗi cập nhật: $e', isError: true);
      setDialogState(() {});
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: AppColors.gray500), const SizedBox(width: 12), SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.gray500, fontWeight: FontWeight.w500))), Expanded(child: Text(value, style: const TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold)))]));
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final status = req['status'] ?? 'pending';
    
    final date = DateTime.parse(req['createdAt'] ?? DateTime.now().toIso8601String()).toLocal();
    final isOverdue = status == 'pending' && DateTime.now().difference(date).inHours >= 24;
    final shortId = req['id'].toString().substring(req['id'].toString().length - 4).toUpperCase();
    String prefix = 'RQ';
    final String categoryName = req['categoryName'] ?? '';
    if (categoryName.isNotEmpty) { prefix = categoryName.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join(''); }
    final formattedId = '#$prefix-${date.day}${date.month}-$shortId';
    final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

    Color statusColor; Color statusBg; String statusText;
    switch (status) {
      case 'approved': case 'completed': statusColor = const Color(0xFF10B981); statusBg = const Color(0xFFD1FAE5); statusText = 'Đã duyệt'; break;
      case 'rejected': statusColor = const Color(0xFFEF4444); statusBg = const Color(0xFFFEE2E2); statusText = 'Từ chối'; break;
      case 'processing': statusColor = const Color(0xFFF59E0B); statusBg = const Color(0xFFFEF3C7); statusText = 'Đang xử lý'; break;
      default: statusColor = const Color(0xFF3B82F6); statusBg = const Color(0xFFDBEAFE); statusText = 'Chờ xử lý';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false), cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(24), transform: Matrix4.translationValues(0, _isHovered ? -8 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(
            color: isOverdue ? AppColors.danger : (_isHovered ? statusColor.withValues(alpha: 0.6) : Colors.white), 
            width: isOverdue ? 2.5 : (_isHovered ? 2.0 : 1.5)
          ),
          boxShadow: [BoxShadow(color: _isHovered ? statusColor.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03), blurRadius: _isHovered ? 24 : 10, offset: Offset(0, _isHovered ? 12 : 4))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(req['studentName'].toString().substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primarySV, fontSize: 18))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(req['studentName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis), 
                      Text('$formattedId • MSSV: ${req['studentId']}', style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600))
                    ]
                  )
                ),
                if (isOverdue) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('⚠️ TRỄ HẠN', style: TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)), child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 20),
            Row(children: [const Icon(Icons.file_copy_rounded, size: 16, color: AppColors.gray500), const SizedBox(width: 8), Expanded(child: Text(categoryName, style: const TextStyle(fontSize: 13, color: AppColors.gray900, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.gray500), const SizedBox(width: 8), Text(timeStr, style: const TextStyle(fontSize: 13, color: AppColors.gray500))]),
            const Spacer(),
            const Divider(height: 1, color: AppColors.gray200), const SizedBox(height: 12),
            
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showRequestDetailsDialog(context, req, statusColor, statusBg, statusText),
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  padding: const EdgeInsets.symmetric(vertical: 10), 
                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      Icon(Icons.remove_red_eye_rounded, size: 16, color: statusColor), 
                      const SizedBox(width: 8), 
                      Text((status == 'pending' || status == 'processing') ? 'Xem & Xử lý đơn' : 'Xem chi tiết', style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold))
                    ]
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}