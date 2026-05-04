import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class RequestDetailScreen extends StatefulWidget {
  final String title;
  final int statusCode; 
  final Color color;
  final IconData icon;

  const RequestDetailScreen({
    super.key,
    required this.title,
    required this.statusCode,
    required this.color,
    required this.icon,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  // Biến lưu danh sách các file người dùng đã chọn
  List<String> _attachedFiles = [];
  // Biến lưu nội dung ghi chú người dùng nhập vào
  final TextEditingController _noteController = TextEditingController();

  String get statusName {
    switch (widget.statusCode) {
      case 0: return 'Đã huỷ';
      case 1: return 'Chờ tiếp nhận';
      case 2: return 'Đang xử lý';
      case 3: return 'Cần bổ sung';
      case 4: return 'Hoàn thành';
      default: return 'Không xác định';
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

                    // Luồng hiển thị thông tin
                    if (widget.statusCode == 3) _buildAdminFeedbackSection(context),
                    if (widget.statusCode == 0) _buildCancelReasonSection(),
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

  // --- CÁC HÀM XÂY DỰNG GIAO DIỆN CŨ (Giữ nguyên logic) ---
  Widget _buildTimeline() {
    int currentStep = 1;
    if (widget.statusCode == 2 || widget.statusCode == 3) currentStep = 2;
    if (widget.statusCode == 4) currentStep = 3;
    if (widget.statusCode == 0) currentStep = 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineStep('Tiếp nhận', '08:00 11/4', 1, currentStep, widget.color, isCancel: widget.statusCode == 0),
        Expanded(child: _buildTimelineDivider(currentStep >= 2, widget.color)),
        _buildTimelineStep('Đang xử lý', currentStep >= 2 ? '10:00 12/4' : '', 2, currentStep, widget.color),
        Expanded(child: _buildTimelineDivider(currentStep >= 3, widget.color)),
        _buildTimelineStep('Hoàn thành', widget.statusCode == 4 ? '14:00 12/4' : '', 3, currentStep, widget.color),
      ],
    );
  }

  Widget _buildTimelineStep(String label, String time, int stepIndex, int currentStep, Color activeColor, {bool isCancel = false}) {
    bool isPast = stepIndex < currentStep;
    bool isCurrent = stepIndex == currentStep;
    bool isFullyCompleted = isCurrent && widget.statusCode == 4; 

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
      decoration: BoxDecoration(color: widget.statusCode == 0 ? AppColors.dangerLight : widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle), child: Icon(widget.icon, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.gray900)), const SizedBox(height: 4), const Text('Mã đơn: #RQ-0123', style: TextStyle(fontSize: 13, color: AppColors.gray500))])),
        ],
      ),
    );
  }

  // =====================================================================
  // 🔥 PHẦN MỚI: UI UPLOAD FILE & BOTTOM SHEET CHO TRẠNG THÁI "CẦN BỔ SUNG"
  // =====================================================================
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
            child: const Text('Ảnh chụp biên lai học phí của em bị mờ. Vui lòng tải lên ảnh khác!'),
          ),
          const SizedBox(height: 16),

          // Hiển thị danh sách các file ĐÃ CHỌN
          if (_attachedFiles.isNotEmpty) ..._attachedFiles.map((fileName) => _buildSelectedFileItem(fileName)),

          // Nút bấm "Nhấn để chọn tệp..."
          GestureDetector(
            onTap: () => _showAttachmentBottomSheet(context),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.lightSV, 
                // Mẹo: Dùng viền nét đứt (dashed) thì cần package bên thứ 3. 
                // Ở đây mình dùng nền xanh nhạt + viền màu xanh dương để giả lập sự nổi bật.
                border: Border.all(color: AppColors.primarySV.withOpacity(0.4), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: AppColors.primarySV, size: 28), 
                  SizedBox(height: 8),
                  Text('Nhấn để chọn tệp hoặc chụp ảnh', style: TextStyle(color: AppColors.gray900)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Ô nhập ghi chú
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(hintText: 'Ghi chú thêm...', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12))
          )
        ],
      ),
    );
  }

  // Thiết kế cái hộp chứa tên file đã chọn kèm nút X (Xóa)
  Widget _buildSelectedFileItem(String fileName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: AppColors.gray500, size: 20), 
          const SizedBox(width: 8),
          Expanded(child: Text(fileName, style: const TextStyle(color: AppColors.gray900, fontSize: 13))),
          GestureDetector(
            onTap: () {
              // Logic xoá file khỏi danh sách
              setState(() {
                _attachedFiles.remove(fileName);
              });
            },
            child: const Icon(Icons.close, color: AppColors.danger, size: 20),
          ),
        ],
      ),
    );
  }

  // Bảng Menu trượt từ dưới lên (Bottom Sheet) để chọn hình thức tải
  void _showAttachmentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tải lên minh chứng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primarySV),
                  title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext); // Đóng menu
                    // Giả lập hệ thống vừa chụp xong 1 tấm ảnh
                    setState(() { _attachedFiles.add('IMG_Camera_${DateTime.now().second}.jpg'); });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppColors.primarySV),
                  title: const Text('Chọn ảnh từ Thư viện', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    // Giả lập người dùng chọn 1 file từ thư viện
                    setState(() { _attachedFiles.add('Bien_lai_hoc_phi_moi.png'); });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_outlined, color: AppColors.primarySV),
                  title: const Text('Chọn tệp tài liệu (PDF, DOCX)', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    setState(() { _attachedFiles.add('Don_Xin_Xac_Nhan.pdf'); });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================================

  Widget _buildSentInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin đã gửi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray500)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(8)),
            child: const Text('Em chào thầy cô, em xin được xác nhận vay vốn để nộp hồ sơ ạ.', style: TextStyle(color: AppColors.gray900)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file_outlined, color: AppColors.gray500, size: 20), SizedBox(width: 8),
                Text('Don_Xin_Vay_Von.pdf', style: TextStyle(color: AppColors.gray900, fontSize: 13)),
              ],
            ),
          )
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
                Text('Người huỷ: Bạn', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)), SizedBox(height: 4),
                Text('Lý do: Nộp nhầm loại giấy tờ.', style: TextStyle(color: AppColors.gray500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    if (widget.statusCode == 1) { 
      // Nút Huỷ yêu cầu (Viền xanh, chữ xanh giống Figma)
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showCancelDialog(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primarySV, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Huỷ yêu cầu', style: TextStyle(color: AppColors.primarySV, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    } else if (widget.statusCode == 3) { 
      // Nút Gửi bổ sung (Nền xanh, chữ trắng)
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_attachedFiles.isEmpty && _noteController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn tệp hoặc nhập ghi chú trước khi gửi!')));
              } else {
                print("Đã gửi file bổ sung: $_attachedFiles");
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi thông tin bổ sung thành công!')));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primarySV,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
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