// lib/ui/screens/student/request_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../../core/theme.dart';
import '../../../models/request_model.dart';
import '../../widgets/glass_toast.dart';

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request;
  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isCanceling = false;

  String _formatTimeStr(String? isoStr) {
    if (isoStr == null) return '--:--\n--/--';
    final date = DateTime.parse(isoStr).toLocal();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}\n${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true, minScale: 0.5, maxScale: 4.0,
              child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(url, fit: BoxFit.contain)),
            ),
            Positioned(
              top: 10, right: 10,
              child: CircleAvatar(backgroundColor: Colors.black54, child: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context))),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gray900, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('Chi tiết yêu cầu', style: TextStyle(color: AppColors.gray900, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('requests')
            .stream(primaryKey: ['id'])
            .eq('id', widget.request.id)
            .limit(1),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primarySV));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không tìm thấy dữ liệu đơn yêu cầu.'));
          }

          final reqData = snapshot.data!.first;
          final String status = (reqData['status'] ?? 'pending').toString().toLowerCase();

          Color statusColor;
          String statusLabel;
          switch (status) {
            case 'approved':
            case 'completed':
              statusColor = AppColors.success;
              statusLabel = 'Hoàn thành';
              break;
            case 'rejected':
              statusColor = AppColors.danger;
              statusLabel = 'Bị từ chối';
              break;
            case 'processing':
              statusColor = AppColors.warning;
              statusLabel = 'Đang xử lý';
              break;
            default:
              statusColor = AppColors.primarySV;
              statusLabel = 'Chờ nhận';
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(reqData, statusColor, statusLabel),
                        const SizedBox(height: 32),
                        const Text('Tiến trình xử lý', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        _buildTimeline(reqData, status),
                        const SizedBox(height: 32),
                        
                        if (status == 'approved' || status == 'completed' || status == 'rejected') ...[
                          _buildStaffFeedbackSection(reqData, status),
                          const SizedBox(height: 32),
                        ],

                        const Text('Nội dung đã gửi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildSentInfoSection(reqData),
                      ],
                    ),
                  ),
                ),
                if (status == 'pending') _buildBottomAction(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> reqData, Color statusColor, String statusLabel) {
    final date = DateTime.parse(reqData['createdAt'] ?? DateTime.now().toIso8601String()).toLocal();
    final shortId = widget.request.id.length > 4 ? widget.request.id.substring(widget.request.id.length - 4).toUpperCase() : '...';
    
    String prefix = 'RQ';
    if (widget.request.categoryName.isNotEmpty) {
      prefix = widget.request.categoryName.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join('');
    }
    final formattedId = '#$prefix-${date.day}${date.month}-$shortId';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.description_outlined, color: statusColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.request.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(child: Text(formattedId, style: TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () { Clipboard.setData(ClipboardData(text: formattedId)); GlassToast.show(context, 'Đã sao chép mã đơn!'); },
                      child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primarySV)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)),
            child: Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> reqData, String status) {
    final hasProcessed = reqData['processedAt'] != null;
    final hasCompleted = reqData['completedAt'] != null;
    final hasRejected = reqData['rejectedAt'] != null || status == 'rejected';

    int timelineState = 1;
    if (status == 'completed' || status == 'approved' || hasCompleted) {
      timelineState = 3;
    } else if (status == 'processing' || hasProcessed) {
      timelineState = hasRejected ? -2 : 2;
    } else if (hasRejected) {
      timelineState = -1;
    }

    Decoration line1Decoration; Decoration line2Decoration;

    if (timelineState == 2 || timelineState == 3) {
      line1Decoration = const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primarySV, AppColors.warning]));
    } else if (timelineState == -2) {
      line1Decoration = const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primarySV, AppColors.danger]));
    } else {
      line1Decoration = const BoxDecoration(color: AppColors.gray200); 
    }

    if (timelineState == 3) {
      line2Decoration = const BoxDecoration(gradient: LinearGradient(colors: [AppColors.warning, AppColors.success]));
    } else {
      line2Decoration = const BoxDecoration(color: AppColors.gray200); 
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.gray100.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          Positioned(
            top: 16, left: 0, right: 0,
            child: Row(
              children: [
                const Spacer(flex: 1),
                Expanded(flex: 2, child: Container(height: 3, decoration: line1Decoration)),
                Expanded(flex: 2, child: Container(height: 3, decoration: line2Decoration)),
                const Spacer(flex: 1),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNode(title: 'Tiếp nhận', time: _formatTimeStr(reqData['createdAt']), circleColor: timelineState == -1 ? AppColors.danger : AppColors.primarySV, borderColor: timelineState == -1 ? AppColors.danger : AppColors.primarySV, icon: timelineState == -1 ? const Icon(Icons.close_rounded, color: Colors.white, size: 16) : (timelineState == 1 ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded, color: Colors.white, size: 16)), isLightLabel: false),
              _buildNode(title: timelineState == -1 ? 'Bị từ chối' : 'Đang xử lý', time: _formatTimeStr(reqData['processedAt'] ?? (timelineState == -1 ? reqData['rejectedAt'] : null)), circleColor: (timelineState == 1 || timelineState == -1) ? Colors.white : (timelineState == -2 ? AppColors.danger : AppColors.warning), borderColor: (timelineState == 1 || timelineState == -1) ? AppColors.gray200 : (timelineState == -2 ? AppColors.danger : AppColors.warning), icon: timelineState == -2 ? const Icon(Icons.close_rounded, color: Colors.white, size: 16) : ((timelineState == 2) ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : (timelineState == 3 ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null)), isLightLabel: timelineState == 1 || timelineState == -1),
              _buildNode(title: timelineState == -2 ? 'Đã huỷ' : 'Hoàn thành', time: _formatTimeStr(reqData['completedAt'] ?? reqData['rejectedAt']), circleColor: (timelineState == 3) ? AppColors.success : ((timelineState == -2) ? AppColors.danger : Colors.white), borderColor: (timelineState == 3) ? AppColors.success : ((timelineState == -2) ? AppColors.danger : AppColors.gray200), icon: (timelineState == 3 || timelineState == -2) ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null, isLightLabel: timelineState != 3 && timelineState != -2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNode({required String title, required String time, required Color circleColor, required Color borderColor, required Widget? icon, required bool isLightLabel}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle, border: Border.all(color: borderColor, width: 2), boxShadow: circleColor != Colors.white ? [BoxShadow(color: circleColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : []), alignment: Alignment.center, child: icon),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: isLightLabel ? FontWeight.w500 : FontWeight.bold, color: isLightLabel ? AppColors.gray500 : AppColors.gray900)),
          const SizedBox(height: 4),
          Text(time.isNotEmpty ? time : '\n', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.gray500, height: 1.2, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<String> _fetchStaffName(String? uid) async {
    if (uid == null || uid.isEmpty) return 'Ban Giáo vụ';
    try {
      final res = await Supabase.instance.client.from('users').select('name').eq('uid', uid).maybeSingle();
      return res?['name'] ?? 'Ban Giáo vụ';
    } catch (e) { return 'Ban Giáo vụ'; }
  }

  Widget _buildStaffFeedbackSection(Map<String, dynamic> reqData, String status) {
    final String note = reqData['note'] ?? 'Yêu cầu của bạn đã được kiểm tra và xử lý.';
    final bool isApproved = status == 'approved' || status == 'completed';

    List<dynamic> staffFiles = [];
    if (reqData['attachedFiles'] is List) {
      staffFiles = reqData['attachedFiles'];
    } else if (reqData['attachedFiles'] is String && reqData['attachedFiles'].toString().trim().isNotEmpty) {
      try {
        staffFiles = jsonDecode(reqData['attachedFiles']);
      } catch (_) {
        final str = reqData['attachedFiles'].toString().trim();
        if (str.startsWith('{') && str.endsWith('}')) {
          staffFiles = str.substring(1, str.length - 1).split(',').map((e) => e.replaceAll('"', '').trim()).where((e) => e.isNotEmpty).toList();
        } else if (str.startsWith('http')) {
          staffFiles = [str];
        }
      }
    }

    return FutureBuilder<String>(
      future: _fetchStaffName(reqData['staffUid']), 
      builder: (context, snapshot) {
        final staffName = snapshot.data ?? 'Ban Giáo vụ';
        
        return Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: isApproved ? AppColors.success.withValues(alpha: 0.08) : AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: isApproved ? AppColors.success.withValues(alpha: 0.3) : AppColors.danger.withValues(alpha: 0.3), width: 1.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isApproved ? AppColors.success : AppColors.danger, size: 22),
                  const SizedBox(width: 10),
                  Text(isApproved ? 'Được duyệt bởi $staffName' : 'Bị từ chối bởi $staffName', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: isApproved ? AppColors.success : AppColors.danger)),
                ],
              ),
              const SizedBox(height: 12),
              Text('"$note"', style: const TextStyle(color: AppColors.gray900, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic)),
              
              if (staffFiles.isNotEmpty) ...[
                const SizedBox(height: 16), const Divider(), const SizedBox(height: 10),
                const Text('Tệp tài liệu Giáo vụ đính kèm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.gray500)),
                const SizedBox(height: 10),
                
                // ─── 🎯 FIX LỖI: VÒNG LẶP RENDER TOÀN BỘ FILE TRẢ VỀ TỪ GIÁO VỤ ───
                ...staffFiles.map((fileUrl) {
                  String displayFileName = fileUrl.toString().split('/').last;
                  if (displayFileName.length > 25) displayFileName = '...${displayFileName.substring(displayFileName.length - 25)}';
                  bool isImage = fileUrl.toString().toLowerCase().contains('.jpg') || fileUrl.toString().toLowerCase().contains('.jpeg') || fileUrl.toString().toLowerCase().contains('.png');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14), 
                      onTap: () {
                        if (isImage) {
                          _showImagePreview(context, fileUrl.toString());
                        } else {
                          launchUrl(Uri.parse(fileUrl.toString()), mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
                        child: Row(
                          children: [
                            Icon(isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded, color: isImage ? Colors.blue : Colors.redAccent, size: 22), 
                            const SizedBox(width: 12), 
                            Expanded(child: Text(displayFileName, style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline))), 
                            const Icon(Icons.download_for_offline_rounded, color: AppColors.gray500, size: 18)
                          ]
                        )
                      ),
                    ),
                  );
                }),
              ]
            ],
          ),
        );
      }
    );
  }

  Widget _buildSentInfoSection(Map<String, dynamic> reqData) {
    final files = reqData['attachmentUrls'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.gray200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.gray100.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
            child: Text(reqData['reason'] ?? '', style: const TextStyle(color: AppColors.gray900, fontSize: 14, height: 1.5)),
          ),
          const SizedBox(height: 20),
          const Text('Tệp đính kèm của bạn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 10),
          if (files.isEmpty) const Text('Không có tệp đính kèm.', style: TextStyle(color: AppColors.gray500, fontStyle: FontStyle.italic, fontSize: 13))
          else ...files.map((fileUrl) {
              String displayFileName = fileUrl.toString().split('/').last;
              if (displayFileName.length > 25) displayFileName = '...${displayFileName.substring(displayFileName.length - 25)}';
              bool isImage = fileUrl.toString().toLowerCase().contains('.jpg') || fileUrl.toString().toLowerCase().contains('.jpeg') || fileUrl.toString().toLowerCase().contains('.png');

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: isImage ? AppColors.primarySV.withValues(alpha: 0.03) : AppColors.gray100, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14), 
                  // ─── Phân biệt Ảnh (Xem trong App) và Tài Liệu (Xem App Ngoài) ───
                  onTap: () {
                    if (isImage) {
                      _showImagePreview(context, fileUrl.toString());
                    } else {
                      launchUrl(Uri.parse(fileUrl.toString()), mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded, color: isImage ? AppColors.primarySV : AppColors.gray500, size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Text(displayFileName, style: const TextStyle(color: AppColors.gray900, fontSize: 13, fontWeight: FontWeight.w600, decoration: TextDecoration.underline))),
                        const Icon(Icons.visibility_rounded, color: AppColors.gray500, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: _isCanceling ? null : () async {
            setState(() => _isCanceling = true);
            try {
              await Supabase.instance.client.from('requests').update({
                'status': 'rejected',
                'rejectedAt': DateTime.now().toIso8601String(),
                'note': 'Sinh viên chủ động hủy yêu cầu từ giao diện ứng dụng.'
              }).eq('id', widget.request.id);
              
              if (mounted) {
                Navigator.pop(context);
                GlassToast.show(context, 'Đã hủy đơn thành công!');
              }
            } catch (e) {
              setState(() => _isCanceling = false);
              if (mounted) GlassToast.show(context, 'Lỗi hủy đơn: $e', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _isCanceling ? const CircularProgressIndicator(color: Colors.white) : const Text('Huỷ yêu cầu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}