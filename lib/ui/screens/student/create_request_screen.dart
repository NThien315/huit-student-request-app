import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class CreateRequestScreen extends StatefulWidget {
  // Biến này dùng để nhận dữ liệu từ trang Home truyền sang
  final String? initialRequestType;

  const CreateRequestScreen({super.key, this.initialRequestType});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  // Danh sách các loại yêu cầu
  final List<String> _requestTypes = [
    'Đăng ký học phần',
    'Xin cấp bảng điểm',
    'Phúc khảo điểm thi',
    'Đăng ký khoá luận',
    'Xin cấp giấy xác nhận sinh viên',
    'Khác'
  ];

  String? _selectedType;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _subjectCodeController = TextEditingController(); // Dùng cho trường hợp Phúc khảo
  
  List<String> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    // Nếu có truyền initialRequestType từ trang Home và nó nằm trong danh sách, thì chọn luôn
    if (widget.initialRequestType != null && _requestTypes.contains(widget.initialRequestType)) {
      _selectedType = widget.initialRequestType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _subjectCodeController.dispose();
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
        title: const Text('Tạo yêu cầu mới', style: TextStyle(color: AppColors.gray900, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    // 1. Gợi ý Auto-fill
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primarySV.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primarySV, size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text('Thông tin cá nhân (MSSV, Họ tên) của bạn sẽ được tự động đính kèm vào yêu cầu này.', style: TextStyle(color: AppColors.primarySV, fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Form Dropdown: Loại yêu cầu
                    _buildLabel('Loại yêu cầu', isRequired: true),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      hint: const Text('-- Chọn loại yêu cầu --', style: TextStyle(color: AppColors.gray500)),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gray500),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySV)),
                      ),
                      items: _requestTypes.map((String type) {
                        return DropdownMenuItem<String>(value: type, child: Text(type, style: const TextStyle(color: AppColors.gray900)));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() { _selectedType = newValue; });
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. UI ĐỘNG: Nếu chọn Phúc khảo, hiện thêm ô Mã môn học
                    if (_selectedType == 'Phúc khảo điểm thi') ...[
                      _buildLabel('Mã môn học / Tên môn', isRequired: true),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _subjectCodeController, hintText: 'VD: 01010001 - Cấu trúc dữ liệu'),
                      const SizedBox(height: 20),
                    ],

                    // 4. Form TextField: Nội dung (Nhiều dòng)
                    _buildLabel('Nội dung', isRequired: false),
                    const SizedBox(height: 8),
                    _buildTextField(controller: _contentController, hintText: 'Trình bày lý do và mong muốn...', maxLines: 5),
                    const SizedBox(height: 24),

                    // 5. Khu vực Upload File (Tái sử dụng)
                    _buildLabel('Tệp đính kèm / Minh chứng', isRequired: false),
                    const SizedBox(height: 8),
                    if (_attachedFiles.isNotEmpty) ..._attachedFiles.map((fileName) => _buildSelectedFileItem(fileName)),
                    GestureDetector(
                      onTap: () => _showAttachmentBottomSheet(context),
                      child: Container(
                        // ... [Giữ nguyên giao diện nút upload] ...
                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.lightSV, 
                          border: Border.all(color: AppColors.primarySV.withOpacity(0.4), width: 1.5),
                          borderRadius: BorderRadius.circular(12),
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
                  ],
                ),
              ),
            ),

            // Nút Gửi yêu cầu cố định ở dưới
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedType == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn Loại yêu cầu!')));
                      return;
                    }
                    
                    // TODO: Gọi API lưu dữ liệu

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo yêu cầu thành công!')));
                    
                    // XỬ LÝ LỖI ĐEN MÀN HÌNH: Kiểm tra xem có thể Pop được không
                    if (Navigator.canPop(context)) {
                      // Nếu đi từ Trang chủ vào -> Trở về trang chủ
                      Navigator.pop(context);
                    } else {
                      // Nếu đang ở Tab của thanh điều hướng -> Xóa trắng Form để người dùng tạo đơn mới
                      setState(() {
                        _selectedType = null;
                        _contentController.clear();
                        _subjectCodeController.clear();
                        _attachedFiles.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primarySV,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Gửi yêu cầu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CÁC HÀM HỖ TRỢ XÂY DỰNG UI ---

  // Hàm vẽ Label có dấu sao đỏ
  Widget _buildLabel(String text, {required bool isRequired}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.gray900),
        children: [
          if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger, fontSize: 14)),
        ],
      ),
    );
  }

  // Hàm vẽ TextField dùng chung
  Widget _buildTextField({required TextEditingController controller, required String hintText, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.gray500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primarySV)),
      ),
    );
  }

  // Hàm vẽ file đã chọn (Copy từ trang chi tiết)
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

  // Bảng chọn tải file (Copy từ trang chi tiết)
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
                ListTile(leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primarySV), title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.w500)), onTap: () { Navigator.pop(bottomSheetContext); setState(() { _attachedFiles.add('IMG_${DateTime.now().second}.jpg'); }); }),
                ListTile(leading: const Icon(Icons.photo_library_outlined, color: AppColors.primarySV), title: const Text('Chọn ảnh từ Thư viện', style: TextStyle(fontWeight: FontWeight.w500)), onTap: () { Navigator.pop(bottomSheetContext); setState(() { _attachedFiles.add('Hinh_anh_minh_chung.png'); }); }),
              ],
            ),
          ),
        );
      },
    );
  }
}