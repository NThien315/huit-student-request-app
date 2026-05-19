// lib/ui/screens/student/request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../models/request_model.dart';
import '../../../services/db_service.dart';
import '../../widgets/glass_toast.dart';

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request;
  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _isCanceling = false;

  Color get statusColor {
    switch (widget.request.status.name) {
      case 'pending': return AppColors.primarySV;
      case 'processing': return AppColors.warning;
      case 'completed': return AppColors.success;
      case 'rejected': return AppColors.danger;
      default: return AppColors.primarySV;
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}\n${date.day}/${date.month}";
  }

  // ─── HÀM PHÓNG TO XEM TRƯỚC ẢNH MINH CHỨNG (HỖ TRỢ ZOOM) ────────────────
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
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                ),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gray900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi tiết yêu cầu', style: TextStyle(color: AppColors.gray900, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 32),
                    const Text('Tiến trình xử lý', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _buildTimeline(),
                    const SizedBox(height: 32),
                    if (widget.request.status.name == 'rejected') _buildCancelReasonSection(),
                    const Text('Nội dung đã gửi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildSentInfoSection(),
                  ],
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final date = widget.request.createdAt;
    final shortId = widget.request.id.length > 4 ? widget.request.id.substring(widget.request.id.length - 4).toUpperCase() : '...';
    
    // Tự động lấy chữ cái đầu của Danh
    String prefix = 'RQ';
    if (widget.request.categoryName.isNotEmpty) {
      prefix = widget.request.categoryName.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join('');
    }
    final formattedId = '#$prefix-${date.day}${date.month}-$shortId';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(Icons.description_outlined, color: statusColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.request.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(formattedId, style: const TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: formattedId));
                        GlassToast.show(context, 'Đã sao chép mã đơn!');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primarySV),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)),
            child: Text(
              widget.request.status.name == 'pending' ? 'Chờ nhận' : (widget.request.status.name == 'rejected' ? 'Đã hủy' : 'Đang xử lý'), 
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final status = widget.request.status.name;
    final hasProcessed = widget.request.processedAt != null;
    final hasCompleted = widget.request.completedAt != null;
    final hasRejected = widget.request.rejectedAt != null || status == 'rejected';

    int timelineState = 1;
    if (status == 'completed' || hasCompleted) {
      timelineState = 3;
    } else if (status == 'processing' || hasProcessed) {
      timelineState = hasRejected ? -2 : 2;
    } else if (hasRejected) {
      timelineState = -1;
    }

    Decoration line1Decoration;
    Decoration line2Decoration;

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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNode(
                title: 'Tiếp nhận',
                time: _formatTime(widget.request.createdAt),
                circleColor: timelineState == -1 ? AppColors.danger : AppColors.primarySV,
                borderColor: timelineState == -1 ? AppColors.danger : AppColors.primarySV,
                icon: timelineState == -1 
                    ? const Icon(Icons.close_rounded, color: Colors.white, size: 16)
                    : (timelineState == 1 ? _buildLoadingIcon() : const Icon(Icons.check_rounded, color: Colors.white, size: 16)),
                isLightLabel: false,
              ),
              _buildNode(
                title: timelineState == -1 ? 'Bị huỷ' : 'Đang xử lý',
                time: _formatTime(widget.request.processedAt ?? (timelineState == -1 ? widget.request.rejectedAt : null)),
                circleColor: (timelineState == 1 || timelineState == -1) ? Colors.white : (timelineState == -2 ? AppColors.danger : AppColors.warning),
                borderColor: (timelineState == 1 || timelineState == -1) ? AppColors.gray200 : (timelineState == -2 ? AppColors.danger : AppColors.warning),
                icon: timelineState == -2
                    ? const Icon(Icons.close_rounded, color: Colors.white, size: 16)
                    : ((timelineState == 2) ? _buildLoadingIcon() : (timelineState == 3 ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null)),
                isLightLabel: timelineState == 1 || timelineState == -1,
              ),
              _buildNode(
                title: timelineState == -2 ? 'Đã huỷ' : 'Hoàn thành',
                time: _formatTime(widget.request.completedAt),
                circleColor: timelineState == 3 ? AppColors.success : Colors.white,
                borderColor: timelineState == 3 ? AppColors.success : AppColors.gray200,
                icon: timelineState == 3 ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                isLightLabel: timelineState != 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIcon() {
    return const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
  }

  Widget _buildNode({
    required String title, required String time,
    required Color circleColor, required Color borderColor,
    required Widget? icon, required bool isLightLabel,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: circleColor, shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: circleColor != Colors.white ? [BoxShadow(color: circleColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: isLightLabel ? FontWeight.w500 : FontWeight.bold, color: isLightLabel ? AppColors.gray500 : AppColors.gray900)),
          const SizedBox(height: 4),
          Text(time.isNotEmpty ? time : '\n', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.gray500, height: 1.2, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── HIỂN THỊ NỘI DUNG ĐÃ GỬI & FILE MINH CHỨNG ĐẦY ĐỦ ──────────────────
  Widget _buildSentInfoSection() {
    final files = widget.request.attachmentUrls; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Khối văn bản nội dung lý do gửi yêu cầu
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16), 
            decoration: BoxDecoration(color: AppColors.gray100.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
            child: Text(widget.request.reason, style: const TextStyle(color: AppColors.gray900, fontSize: 14, height: 1.5)),
          ),
          const SizedBox(height: 20),
          
          const Text('Tệp đính kèm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 10),
          
          if (files.isEmpty)
             const Text('Không có tệp đính kèm.', style: TextStyle(color: AppColors.gray500, fontStyle: FontStyle.italic, fontSize: 13))
          else
            ...files.map((fileUrl) {
              // Xử lý rút gọn tên tệp hiển thị tránh tràn dòng UI
              String displayFileName = fileUrl.split('/').last;
              if (displayFileName.length > 25) displayFileName = '...${displayFileName.substring(displayFileName.length - 25)}';
              
              bool isImage = fileUrl.toLowerCase().contains('.jpg') || 
                            fileUrl.toLowerCase().contains('.jpeg') || 
                            fileUrl.toLowerCase().contains('.png');

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isImage ? AppColors.primarySV.withValues(alpha: 0.03) : AppColors.gray100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showImagePreview(context, fileUrl), // Kích hoạt popup xem ảnh phóng to
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(isImage ? Icons.image_rounded : Icons.insert_drive_file_rounded, 
                             color: isImage ? AppColors.primarySV : AppColors.gray500, size: 22), 
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

  Widget _buildCancelReasonSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.danger),
          SizedBox(width: 12),
          Expanded(child: Text('Yêu cầu đã bị hủy hoặc từ chối xử lý từ phía nhà trường.', style: TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    if (widget.request.status.name != 'pending') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: _isCanceling ? null : () async {
            setState(() => _isCanceling = true);
            await DbService().updateRequestStatus(widget.request.id, 'rejected');
            if (mounted) {
               Navigator.pop(context);
               GlassToast.show(context, 'Đã hủy đơn thành công!');
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _isCanceling ? const CircularProgressIndicator(color: Colors.white) : const Text('Huỷ yêu cầu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}