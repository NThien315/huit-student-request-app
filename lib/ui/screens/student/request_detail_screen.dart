import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/request_model.dart';

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request; // Thay các biến lẻ bằng biến này

  const RequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  List<String> _attachedFiles = [];
  final TextEditingController _noteController = TextEditingController();

  // --- CÁC HÀM GETTER ĐỂ LẤY THÔNG TIN TỪ DATABASE ---
  String get statusName {
    switch (widget.request.status.name) {
      case 'pending': return 'Chờ tiếp nhận';
      case 'processing': return 'Đang xử lý';
      case 'completed': return 'Hoàn thành';
      case 'rejected': return 'Đã huỷ';
      default: return 'Không xác định';
    }
  }

  int get statusCode {
    switch (widget.request.status.name) {
      case 'pending': return 1;
      case 'processing': return 2;
      case 'completed': return 4;
      case 'rejected': return 0;
      default: return 1;
    }
  }

  Color get statusColor {
    switch (widget.request.status.name) {
      case 'pending': return AppColors.primarySV;
      case 'processing': return AppColors.warning;
      case 'completed': return AppColors.success;
      case 'rejected': return AppColors.danger;
      default: return AppColors.primarySV;
    }
  }

  IconData get statusIcon {
    switch (widget.request.status.name) {
      case 'pending': return Icons.more_horiz;
      case 'processing': return Icons.hourglass_empty;
      case 'completed': return Icons.check;
      case 'rejected': return Icons.close;
      default: return Icons.more_horiz;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.primarySV),
        centerTitle: true,
        title: const Text('Chi tiết yêu cầu', style: TextStyle(color: AppColors.gray900, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeline(),
                    const SizedBox(height: 24),
                    _buildHeaderCard(),
                    const SizedBox(height: 24),
                    if (statusCode == 3) _buildAdminFeedbackSection(context),
                    if (statusCode == 0) _buildCancelReasonSection(),
                    _buildSentInfoSection(),
                  ],
                ),
              ),
            ),
            _buildBottomAction(context),
          ],
        ),
      ),
    );
  }

  // --- CÁC HÀM XÂY DỰNG GIAO DIỆN ---
  Widget _buildTimeline() {
    int currentStep = 1;
    if (statusCode == 2 || statusCode == 3) currentStep = 2;
    if (statusCode == 4) currentStep = 3;
    if (statusCode == 0) currentStep = 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineStep('Tiếp nhận', '', 1, currentStep, statusColor, isCancel: statusCode == 0),
        Expanded(child: _buildTimelineDivider(currentStep >= 2, statusColor)),
        _buildTimelineStep('Đang xử lý', '', 2, currentStep, statusColor),
        Expanded(child: _buildTimelineDivider(currentStep >= 3, statusColor)),
        _buildTimelineStep('Hoàn thành', '', 3, currentStep, statusColor),
      ],
    );
  }

  Widget _buildTimelineStep(String label, String time, int stepIndex, int currentStep, Color activeColor, {bool isCancel = false}) {
    bool isPast = stepIndex < currentStep;
    bool isCurrent = stepIndex == currentStep;
    bool isFullyCompleted = isCurrent && statusCode == 4; 

    Widget iconWidget;
    if (isCancel) {
      iconWidget = const Icon(Icons.close, color: Colors.white, size: 18);
    } else if (isPast || isFullyCompleted) {
      iconWidget = const Icon(Icons.check, color: Colors.white, size: 18);
    } else if (isCurrent) {
      iconWidget = const Icon(Icons.more_horiz, color: Colors.white, size: 18);
    } else {
      iconWidget = Text('$stepIndex', style: TextStyle(color: AppColors.gray300, fontWeight: FontWeight.bold));
    }

    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: isCancel ? AppColors.danger : ((isPast || isCurrent) ? activeColor : AppColors.white), shape: BoxShape.circle, border: Border.all(color: isCancel ? AppColors.danger : ((isPast || isCurrent) ? activeColor : AppColors.gray200), width: 1.5)),
          alignment: Alignment.center, child: iconWidget,
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (isPast || isCurrent || isCancel) ? AppColors.gray900 : AppColors.gray500)),
        if (time.isNotEmpty) Text(time, style: const TextStyle(fontSize: 10, color: AppColors.gray500)),
      ],
    );
  }

  Widget _buildTimelineDivider(bool isActive, Color activeColor) => Container(margin: const EdgeInsets.only(top: 16), height: 2, color: isActive ? activeColor : AppColors.gray200);

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: statusCode == 0 ? AppColors.dangerLight : statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle), child: Icon(statusIcon, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.request.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.gray900)), 
            const SizedBox(height: 4), 
            Builder(
              builder: (context) {
                // 1. Lấy ngày gửi và 4 ký tự cuối của ID
                final date = widget.request.createdAt;
                final shortId = widget.request.id.substring(widget.request.id.length - 4).toUpperCase();
                
                // 2. Tự động lấy chữ cái đầu của Loại yêu cầu (VD: "Phúc khảo bài thi" -> "PKBT")
                String prefix = 'RQ'; // Mặc định
                if (widget.request.categoryName.isNotEmpty) {
                  prefix = widget.request.categoryName.split(' ').map((word) => word.isNotEmpty ? word[0].toUpperCase() : '').join('');
                }

                // 3. Ghép lại: VD #PKBT-1305-XYZ9
                final formattedId = '#$prefix-${date.day}${date.month}-$shortId';
                
                return Text('Mã đơn: $formattedId', style: const TextStyle(fontSize: 13, color: AppColors.gray500));
              }
            )
          ])),
        ],
      ),
    );
  }

  // Khối Giáo vụ phản hồi (Giữ UI mẫu)
  Widget _buildAdminFeedbackSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppColors.warning), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin từ giáo vụ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray500)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(8)),
            child: const Text('Vui lòng bổ sung thêm thông tin!'),
          ),
          const SizedBox(height: 16),
          if (_attachedFiles.isNotEmpty) ..._attachedFiles.map((fileName) => _buildSelectedFileItem(fileName)),
          GestureDetector(
            onTap: () => _showAttachmentBottomSheet(context),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightSV, border: Border.all(color: AppColors.primarySV.withOpacity(0.4), width: 1.5), borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppColors.primarySV, size: 28), SizedBox(height: 8),
                  Text('Nhấn để chọn tệp hoặc chụp ảnh', style: TextStyle(color: AppColors.gray900)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: const InputDecoration(hintText: 'Ghi chú thêm...', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)))
        ],
      ),
    );
  }

  Widget _buildSelectedFileItem(String fileName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: AppColors.gray500, size: 20), const SizedBox(width: 8),
          Expanded(child: Text(fileName, style: const TextStyle(color: AppColors.gray900, fontSize: 13))),
          GestureDetector(onTap: () { setState(() { _attachedFiles.remove(fileName); }); }, child: const Icon(Icons.close, color: AppColors.danger, size: 20)),
        ],
      ),
    );
  }

  void _showAttachmentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tải lên minh chứng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)), const SizedBox(height: 16),
                ListTile(leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primarySV), title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.w500)), onTap: () { Navigator.pop(bottomSheetContext); setState(() { _attachedFiles.add('IMG_Camera_${DateTime.now().second}.jpg'); }); }),
                ListTile(leading: const Icon(Icons.photo_library_outlined, color: AppColors.primarySV), title: const Text('Chọn ảnh từ Thư viện', style: TextStyle(fontWeight: FontWeight.w500)), onTap: () { Navigator.pop(bottomSheetContext); setState(() { _attachedFiles.add('Bien_lai.png'); }); }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentInfoSection() {
    // Kéo danh sách file thật từ biến bạn vừa tự thêm
    final files = widget.request.attachedFiles ?? []; 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin đã gửi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray500)),
          const SizedBox(height: 12),
          
          // Khung chứa lý do sinh viên gửi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(8)),
            child: Text(widget.request.reason, style: const TextStyle(color: AppColors.gray900)),
          ),
          const SizedBox(height: 16),
          
          // Xử lý Ẩn/Hiện File
          if (files.isEmpty)
             const Text('Không có tệp đính kèm.', style: TextStyle(color: AppColors.gray500, fontStyle: FontStyle.italic, fontSize: 13))
          else
            ...files.map((fileUrl) {
              String displayFileName = fileUrl.split('/').last;
              if (displayFileName.length > 20) displayFileName = '...${displayFileName.substring(displayFileName.length - 20)}';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, color: AppColors.gray500, size: 20), const SizedBox(width: 8),
                    Text(displayFileName, style: const TextStyle(color: AppColors.gray900, fontSize: 13)),
                  ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin huỷ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray500)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(12)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Người huỷ: Hệ thống / Giáo vụ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)), SizedBox(height: 4),
                Text('Lý do: Không hợp lệ.', style: TextStyle(color: AppColors.gray500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    if (statusCode == 1) { 
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showCancelDialog(context),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppColors.primarySV, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Huỷ yêu cầu', style: TextStyle(color: AppColors.primarySV, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (statusCode == 3) { 
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_attachedFiles.isEmpty && _noteController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn tệp hoặc nhập ghi chú trước khi gửi!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi thông tin bổ sung thành công!')));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: AppColors.primarySV, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Gửi bổ sung', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Huỷ yêu cầu', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có chắc chắn muốn huỷ yêu cầu hiện tại?', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(hintText: 'Lý do huỷ', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), maxLines: 2),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.primarySV), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Quay lại', style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); }, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: AppColors.primarySV, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0), child: const Text('Huỷ yêu cầu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}