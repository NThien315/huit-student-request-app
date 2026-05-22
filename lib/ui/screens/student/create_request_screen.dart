import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../services/db_service.dart';
import '../../../models/category_model.dart';
import '../../../models/request_model.dart';
import '../../../state/auth_provider.dart';
import '../../widgets/glass_toast.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class CreateRequestScreen extends StatefulWidget {
  final String? initialRequestType;
  const CreateRequestScreen({super.key, this.initialRequestType});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  CategoryModel? _selectedCategory;
  int _selectedTab = 0; // 0: Đơn Hành chính, 1: Đơn Học vụ
  
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  // Biến quản lý Môn học thay cho TextField
  List<Map<String, dynamic>> _subjectsList = [];
  String? _selectedSubjectCode;
  
  final List<String> _attachedFiles = []; 
  bool _isSubmitting = false;
  late Stream<List<CategoryModel>> _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream = DbService().getActiveCategoriesStream();
    _fetchSubjects(); // Gọi hàm lấy môn học
    
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && user.phone != null) {
      _phoneController.text = user.phone!;
    }
  }

  // HÀM LẤY DANH SÁCH MÔN HỌC TỪ SUPABASE
  Future<void> _fetchSubjects() async {
    try {
      final data = await Supabase.instance.client.from('subjects').select().order('subjectName');
      if (mounted) {
        setState(() {
          _subjectsList = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải danh sách môn học: $e");
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<String?> _compressImage(String targetPath) async {
    if (!targetPath.toLowerCase().endsWith('.jpg') && 
        !targetPath.toLowerCase().endsWith('.jpeg') && 
        !targetPath.toLowerCase().endsWith('.png')) {
      return targetPath; 
    }
    try {
      final dir = await getTemporaryDirectory();
      final outPath = "${dir.absolute.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        targetPath, outPath, quality: 70, 
      );
      return compressedFile?.path;
    } catch (e) {
      return targetPath; 
    }
  }

  String _getDynamicHint() {
    if (_selectedCategory == null) return '';
    final name = _selectedCategory!.name.toLowerCase();
    
    if (name.contains('bảng điểm')) return '💡 Gợi ý: Vui lòng đính kèm ảnh chụp Thẻ sinh viên hoặc CCCD để phòng đào tạo đối chiếu.';
    if (name.contains('phúc khảo')) return '💡 Gợi ý: Bắt buộc đính kèm ảnh chụp Biên lai đóng lệ phí phúc khảo môn học.';
    if (name.contains('khoá luận') || name.contains('đồ án')) return '💡 Gợi ý: Đính kèm file đề cương (PDF) hoặc phiếu chấp thuận có chữ ký của GV hướng dẫn.';
    if (name.contains('hủy học phần')) return '💡 Gợi ý: Đơn chỉ được phê duyệt hợp lệ nếu nằm trong khung thời gian quy định cho phép hủy môn của trường.';
    if (name.contains('tương đương')) return '💡 Gợi ý: Đính kèm file Bảng điểm trường cũ (PDF) và Đề cương chi tiết của môn học muốn xin xét duyệt tương đương.';
    if (name.contains('thôi học') || name.contains('rút hồ sơ')) return '💡 Gợi ý: Bắt buộc đính kèm Đơn xin thôi học viết tay có chữ ký cam kết đồng ý của Phụ huynh học sinh.';
    return '💡 Gợi ý: Nên đính kèm hình ảnh/tài liệu liên quan để nhà trường kiểm tra và xử lý nhanh hơn.';
  }

  Future<void> _handleSubmit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_selectedCategory == null) {
      GlassToast.show(context, 'Vui lòng chọn loại yêu cầu!', isError: true);
      return;
    }
    // KIỂM TRA VALIDATE DROPDOWN MÔN HỌC
    if (_checkIfNeedSubjectCode() && _selectedSubjectCode == null) {
      GlassToast.show(context, 'Vui lòng chọn môn học liên quan!', isError: true);
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      GlassToast.show(context, 'Vui lòng nhập số điện thoại liên hệ!', isError: true);
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      GlassToast.show(context, 'Vui lòng nhập nội dung chi tiết!', isError: true);
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      GlassToast.show(context, 'Lỗi xác thực: Vui lòng đăng nhập lại!', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> uploadedFileUrls = [];

      if (_attachedFiles.isNotEmpty) {
        for (String path in _attachedFiles) {
          String? finalPath = await _compressImage(path);
          String? url = await DbService().uploadFileToStorage(finalPath ?? path, user.uid);
          if (url != null) uploadedFileUrls.add(url);
        }
      }

      final newRequest = RequestModel(
        id: '', 
        studentUid: user.uid,
        studentName: user.name,
        studentId: user.studentId ?? '',
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        // LẤY GIÁ TRỊ TỪ DROPDOWN NẾU CÓ
        subjectCode: _checkIfNeedSubjectCode() ? _selectedSubjectCode ?? '' : '',
        reason: _contentController.text.trim(),
        attachmentUrls: uploadedFileUrls,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await DbService().createRequest(newRequest);

      if (mounted) {
        GlassToast.show(context, 'Đã gửi yêu cầu thành công!');
        setState(() {
          _selectedCategory = null;
          _selectedSubjectCode = null; // Reset môn học
          _contentController.clear();
          _attachedFiles.clear();
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        GlassToast.show(context, 'Lỗi: ${e.toString()}', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.dark, 
          backgroundColor: AppColors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false, 
          leading: Navigator.canPop(context) 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gray900, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null, 
          centerTitle: true,
          title: const Text('Tạo yêu cầu mới', style: TextStyle(color: AppColors.gray900, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          bottom: false, 
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAutoFillNotice(),
                const SizedBox(height: 24),

                _buildSectionTitle('Phòng ban xử lý đơn', isRequired: true),
                const SizedBox(height: 12),
                _buildSegmentedTabSelector(), 

                const SizedBox(height: 24),
                _buildSectionTitle('Loại yêu cầu', isRequired: true),
                const SizedBox(height: 16),
                _buildCategoryChips(),
                
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(_getDynamicHint(), style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                  )
                ],
                
                const SizedBox(height: 28),
                _buildSectionTitle('Số điện thoại liên hệ', isRequired: true),
                const SizedBox(height: 12),
                _buildSoftTextField(_phoneController, 'Nhập số điện thoại để giáo vụ liên hệ...', keyboardType: TextInputType.phone),

                const SizedBox(height: 28),
                // KHI CẦN NHẬP MÔN HỌC THÌ HIỂN THỊ DROPDOWN
                if (_checkIfNeedSubjectCode()) ...[
                  _buildSectionTitle('Môn học liên quan', isRequired: true),
                  const SizedBox(height: 12),
                  _buildSubjectDropdown(), // Gọi component Dropdown
                  const SizedBox(height: 28),
                ],

                _buildSectionTitle('Nội dung chi tiết', isRequired: true),
                const SizedBox(height: 12),
                _buildSoftTextField(_contentController, 'Trình bày rõ lý do và mong muốn của bạn...', maxLines: 5, maxLength: 500),

                const SizedBox(height: 28),
                _buildSectionTitle('Minh chứng đính kèm'),
                const SizedBox(height: 12),
                _buildAttachmentSection(),
                
                const SizedBox(height: 40),
                _buildBottomAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── GIAO DIỆN COMPONENT ───

  Widget _buildSegmentedTabSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth / 2;
          return Stack(
            children: [
              // ─── KHỐI TRƯỢT ───
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _selectedTab * width,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
              // ─── CHỮ ───
              Row(
                children: [
                  _buildTabItem(0, 'Đơn Hành chính (CTSV)'),
                  _buildTabItem(1, 'Đơn Học vụ (Khoa)'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTab = index;
          _selectedCategory = null; 
          _selectedSubjectCode = null;
        }),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primarySV : AppColors.gray500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _categoriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primarySV));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('Chưa tải được danh mục...', style: TextStyle(color: AppColors.gray500));

        final allCategories = snapshot.data!;
        final filteredCategories = allCategories.where((cat) {
          final name = cat.name.toLowerCase();
          final isAdministrative = name.contains('xác nhận') || name.contains('học phí') || name.contains('bhyt') || name.contains('thẻ sinh viên') || name.contains('thôi học') || name.contains('rút hồ sơ');
          return _selectedTab == 0 ? isAdministrative : !isAdministrative;
        }).toList();

        if (filteredCategories.isEmpty) return const Text('Không có thủ tục nào thuộc nhóm này.', style: TextStyle(color: AppColors.gray500, fontSize: 13));

        // ─── NÂNG CẤP SANG DẠNG THANH CUỘN NGANG CÓ ANIMATION  ───
        return SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredCategories.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final cat = filteredCategories[index];
              final isSelected = _selectedCategory?.id == cat.id;
              
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = cat;
                  _selectedSubjectCode = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primarySV : AppColors.gray100.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected ? [
                      BoxShadow(color: AppColors.primarySV.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                    ] : [],
                  ),
                  child: Center(
                    child: Text(
                      cat.name, 
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.gray900, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, 
                        fontSize: 13
                      )
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // KIỂM TRA ĐƠN NÀO CẦN CHỌN MÔN HỌC
  bool _checkIfNeedSubjectCode() {
    if (_selectedCategory == null) return false;
    final name = _selectedCategory!.name.toLowerCase();
    return name.contains('phúc khảo') || 
           name.contains('hủy học phần') || 
           name.contains('tương đương') || 
           name.contains('môn học') ||
           name.contains('học ghép');
  }

  // GIAO DIỆN DROPDOWN MÔN HỌC
  Widget _buildSubjectDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('Nhấn để chọn môn học...', style: TextStyle(color: AppColors.gray500, fontSize: 14)),
          value: _selectedSubjectCode,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gray500),
          items: _subjectsList.map((subject) {
            return DropdownMenuItem<String>(
              value: subject['subjectCode'],
              child: Text(
                "${subject['subjectCode']} - ${subject['subjectName']}",
                style: const TextStyle(fontSize: 14, color: AppColors.gray900, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedSubjectCode = val);
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
        if (isRequired) const Text(' *', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.danger)),
      ],
    );
  }

  Widget _buildAutoFillNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primarySV.withValues(alpha: 0.15))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.15), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primarySV, size: 18)),
          const SizedBox(width: 14),
          const Expanded(child: Text('Hệ thống sẽ tự động đồng bộ mã sinh viên và tên thật từ hồ sơ HDPE của bạn.', style: TextStyle(color: AppColors.primarySV, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildSoftTextField(TextEditingController controller, String hint, {int maxLines = 1, int? maxLength, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.gray100.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller, maxLines: maxLines, maxLength: maxLength, keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.gray900, fontSize: 14, height: 1.5),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: AppColors.gray500, fontSize: 14),
          contentPadding: const EdgeInsets.all(16), border: InputBorder.none,
          counterStyle: const TextStyle(color: AppColors.gray500, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      children: [
        if (_attachedFiles.isNotEmpty)
          ..._attachedFiles.map((path) {
            String fileName = path.split('/').last;
            return Container(
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.gray200), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.file_present_rounded, color: AppColors.primarySV, size: 22), const SizedBox(width: 12),
                  Expanded(child: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.gray900, fontSize: 13, fontWeight: FontWeight.w500))),
                  GestureDetector(
                    onTap: () => setState(() => _attachedFiles.remove(path)),
                    child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.dangerLight.withValues(alpha: 0.5), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 16)),
                  ),
                ],
              ),
            );
          }),
        GestureDetector(
          onTap: () => _showAttachmentBottomSheet(context),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primarySV.withValues(alpha: 0.25), width: 1.5)),
            child: const Column(
              children: [
                Icon(Icons.cloud_upload_rounded, color: AppColors.primarySV, size: 30), SizedBox(height: 12),
                Text('Tải lên giấy tờ liên quan', style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold, fontSize: 14)), SizedBox(height: 4),
                Text('Định dạng cho phép: JPG, PNG, PDF (Tối đa 5MB)', style: TextStyle(color: AppColors.gray500, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primarySV, disabledBackgroundColor: AppColors.primarySV.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2, shadowColor: AppColors.primarySV.withValues(alpha: 0.3),
        ),
        child: _isSubmitting
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Gửi yêu cầu', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  void _showAttachmentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(2))), const SizedBox(height: 16),
                const Text('Tải lên tài liệu chứng minh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.photo_library_rounded, color: AppColors.primarySV)), 
                  title: const Text('Chọn ảnh từ thiết bị', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900)), 
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final fileSize = await File(pickedFile.path).length();
                      if (!context.mounted) return;
                      if (fileSize > 5 * 1024 * 1024) {
                        GlassToast.show(context, 'Tệp quá lớn! Vui lòng chọn tệp dưới 5MB', isError: true);
                        return;
                      }
                      setState(() => _attachedFiles.add(pickedFile.path));
                    }
                  }
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.attach_file_rounded, color: AppColors.primarySV)), 
                  title: const Text('Đính kèm tệp tài liệu (PDF)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900)), 
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    FilePickerResult? result = await FilePicker.pickFiles();
                    if (result != null && result.files.single.path != null) {
                      if (!context.mounted) return;
                      if (result.files.single.size > 5 * 1024 * 1024) {
                        GlassToast.show(context, 'Tệp quá lớn! Vui lòng chọn tệp dưới 5MB', isError: true);
                        return;
                      }
                      setState(() => _attachedFiles.add(result.files.single.path!));
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