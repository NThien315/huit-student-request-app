import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../services/db_service.dart';
import '../../../models/category_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../state/auth_provider.dart';
import '../../../models/request_model.dart';

class CreateRequestScreen extends StatefulWidget {
  // Biến này dùng để nhận dữ liệu từ trang Home truyền sang
  final String? initialRequestType;

  const CreateRequestScreen({super.key, this.initialRequestType});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  // Biến lưu Loại yêu cầu mà sinh viên đã chọn (Kiểu dữ liệu từ TV2)
  CategoryModel? _selectedCategory;

  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _subjectCodeController = TextEditingController(); // Dùng cho trường hợp Phúc khảo
  
  List<String> _attachedFiles = [];

  @override
  void dispose() {
    _contentController.dispose();
    _subjectCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Ấn ra ngoài để ẩn bàn phím
      child: Scaffold(
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

                      // 2. Form Dropdown: Loại yêu cầu (Dữ liệu từ Firestore)
                      _buildLabel('Loại yêu cầu', isRequired: true),
                      const SizedBox(height: 8),
                      StreamBuilder<List<CategoryModel>>(
                        stream: DbService().getActiveCategories(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text('Không có danh mục nào', style: TextStyle(color: AppColors.gray500));
                          }

                          final categories = snapshot.data!;
                          
                          // 🔥 ĐÂY LÀ ĐOẠN CODE "TÌM NGƯỜI THÂN" ĐỂ SỬA LỖI:
                          // Tìm object mới nhất trong danh sách có ID trùng với ID đã chọn
                          CategoryModel? currentDropdownValue;
                          if (_selectedCategory != null) {
                            try {
                              currentDropdownValue = categories.firstWhere((c) => c.id == _selectedCategory!.id);
                            } catch (e) {
                              // Nếu DB lỡ xóa mất danh mục đó thì cho nó về null
                              currentDropdownValue = null; 
                            }
                          }
                          
                          return DropdownButtonFormField<CategoryModel>(
                            value: currentDropdownValue, // 👉 Truyền biến mới vào đây
                            decoration: InputDecoration(
                              labelStyle: const TextStyle(color: AppColors.gray500),
                              hintText: 'Chọn loại yêu cầu', 
                              hintStyle: const TextStyle(color: AppColors.gray500),
                              filled: true,
                              fillColor: AppColors.gray100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.gray500),
                            items: categories.map((cat) {
                              return DropdownMenuItem<CategoryModel>(
                                value: cat,
                                child: Text(cat.name, style: const TextStyle(color: AppColors.gray900)),
                              );
                            }).toList(),
                            onChanged: (CategoryModel? newValue) {
                              setState(() {
                                _selectedCategory = newValue; // Vẫn lưu lại để submit
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // 3. UI ĐỘNG: Nếu chọn Phúc khảo, hiện thêm ô Mã môn học
                      // Bắt sự kiện thông qua tên của Category
                      if (_selectedCategory?.name.toLowerCase().contains('phúc khảo') ?? false) ...[
                        _buildLabel('Mã môn học / Tên môn', isRequired: true),
                        const SizedBox(height: 8),
                        _buildTextField(controller: _subjectCodeController, hintText: 'VD: 01010001 - Cấu trúc dữ liệu'),
                        const SizedBox(height: 20),
                      ],

                      // 4. Form TextField: Nội dung (Nhiều dòng)
                      _buildLabel('Nội dung / Lý do', isRequired: false),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _contentController, hintText: 'Trình bày lý do và mong muốn...', maxLines: 5),
                      const SizedBox(height: 24),

                      // 5. Khu vực Upload File (Giao diện giữ nguyên)
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
                    onPressed: () async {
                      // 1. Kiểm tra rào chắn (Validation)
                      if (_selectedCategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Vui lòng chọn Loại yêu cầu!'), backgroundColor: AppColors.danger));
                        return;
                      }
                      if (_subjectCodeController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Vui lòng nhập Mã/Tên môn học!'), backgroundColor: AppColors.danger));
                        return;
                      }

                      // 2. KÉO BIẾN USER (Sửa lỗi undefined name 'user')
                      final user = context.read<AuthProvider>().currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Bạn chưa đăng nhập!'), backgroundColor: AppColors.danger));
                        return;
                      }

                      // 3. Tắt bàn phím ảo
                      FocusScope.of(context).unfocus();

                      // 4. Bật vòng xoay chờ
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        // Tạm thời đóng phần upload file để chờ TV2 cập nhật hàm uploadFileToStorage vào db_service.dart
                        /*
                        List<String> uploadedFileUrls = [];
                        if (_attachedFiles.isNotEmpty) {
                          for (String path in _attachedFiles) {
                            // 👉 GỌI HÀM SUPABASE CỦA TV2 Ở ĐÂY
                            // (Bạn gõ DbService(). rồi xem VS Code gợi ý hàm upload nào mới nhất nhé)
                            String? url = await DbService().uploadToSupabase(path, user.uid); 
                            
                            if (url != null) {
                              uploadedFileUrls.add(url);
                            }
                          }
                        }
                        */

                        // Đóng vòng xoay chờ
                        if (context.mounted) Navigator.pop(context);

                        // 5. GỌI HÀM CỦA TV2 (Sửa lỗi missing_required_argument)
                        // TV2 yêu cầu truyền biến lẻ: student, category, reason
                        await DbService().createRequest(
                          student: user,                   // Truyền biến user thật vào đây
                          category: _selectedCategory!,    // Mảng category đã chọn
                          reason: _contentController.text, // Lý do lấy từ ô nhập liệu
                          // Lưu ý: Nếu TV2 có làm biến nhận 'subjectCode' hay mảng file, bạn thêm vào tương ứng nhé
                        );

                        // 6. Dọn form và báo thành công
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi yêu cầu thành công!'), backgroundColor: AppColors.success));
                          setState(() {
                            _selectedCategory = null;
                            _subjectCodeController.clear();
                            _contentController.clear();
                            _attachedFiles.clear();
                          });
                        }

                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); 
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.danger));
                        }
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
      context: context, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tải lên minh chứng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined), 
                  title: const Text('Chọn ảnh từ Thư viện'), 
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    final picker = ImagePicker();
                    // Mở thư viện ảnh thật của điện thoại
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        // Thêm đường dẫn file thật vào danh sách (Sau này đưa cho TV2 upload lên Firebase Storage)
                        _attachedFiles.add(pickedFile.path); 
                      });
                    }
                  }
                ),
                ListTile(
                  leading: const Icon(Icons.attach_file), 
                  title: const Text('Chọn Tệp (PDF, Word...)'), 
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    // Mở trình quản lý file thật
                    FilePickerResult? result = await FilePicker.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      setState(() {
                        _attachedFiles.add(result.files.single.path!);
                      });
                    }
                  }
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}