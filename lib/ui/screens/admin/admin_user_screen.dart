// lib/ui/screens/admin/admin_user_screen.dart
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/services/db_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../widgets/glass_toast.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchTerm = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await Supabase.instance.client.from('users').select().order('name', ascending: true); 
      if (mounted) setState(() { _allUsers = List<Map<String, dynamic>>.from(response); _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatEmail(String input) {
    String email = input.trim().replaceAll(' ', ''); 
    if (email.isEmpty) return '';
    if (!email.contains('@')) email += '@hdpe.edu.vn'; 
    return email;
  }

  Future<void> _resetPassword(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(title: const Text('Đặt lại Mật khẩu', style: TextStyle(color: AppColors.warning)), content: Text('Bạn có chắc muốn đặt lại mật khẩu của "$name" về mặc định là 123456?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning), onPressed: () => Navigator.pop(context, true), child: const Text('Đồng ý', style: TextStyle(color: Colors.white)))])
    );
    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.admin.updateUserById(uid, attributes: AdminUserAttributes(password: '123456'));
        await DbService().logAudit('UPDATE', 'Mật khẩu', 'Đã Reset mật khẩu của tài khoản "$name" về mặc định.');
        if (mounted) GlassToast.show(context, 'Đã đặt lại mật khẩu thành 123456');
      } catch (e) {
        if (mounted) GlassToast.show(context, 'Lỗi reset: Cần cấp Service Role Key cho Admin!', isError: true);
      }
    }
  }

  // UPDATE: Chỉ hiện Popup Cảnh báo, cấm xóa nếu bị ràng buộc
  Future<void> _deleteUser(dynamic uid) async {
    try {
      final tiedRequests = await Supabase.instance.client.from('requests').select('id, categoryName').or('studentUid.eq.$uid,staffUid.eq.$uid');
      
      if (tiedRequests.isNotEmpty) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.warning), SizedBox(width: 8), Text('Tài khoản đang bị ràng buộc!', style: TextStyle(color: AppColors.warning))]),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Không thể xóa! Tài khoản này đang liên kết với các yêu cầu sau:'),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150), decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                    child: ListView.builder(
                      shrinkWrap: true, itemCount: tiedRequests.length,
                      itemBuilder: (context, index) => ListTile(
                        dense: true, leading: const Icon(Icons.file_copy_rounded, size: 16, color: AppColors.gray500),
                        title: Text(tiedRequests[index]['categoryName'] ?? 'Yêu cầu'), subtitle: Text('Mã yêu cầu: ${tiedRequests[index]['id']}', style: const TextStyle(fontSize: 11)),
                      )
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('💡 Hướng dẫn xử lý:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primarySV)),
                  const Text('Vui lòng sang tab "Giám sát Yêu cầu", tìm và xóa các mã yêu cầu trên trước khi tiến hành xóa tài khoản này.', style: TextStyle(color: AppColors.gray500, fontSize: 13)),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)))],
          )
        );
        return; // Dừng lại ở đây, không cho xóa
      }

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(title: const Text('Xóa Tài khoản', style: TextStyle(color: AppColors.danger)), content: const Text('Xóa vĩnh viễn user khỏi hệ thống. Đồng ý?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.white)))])
      );
      if (confirm != true) return;

      await Supabase.instance.client.auth.admin.deleteUser(uid);
      await Supabase.instance.client.from('users').delete().eq('uid', uid);
      await DbService().logAudit('DELETE', 'Tài khoản User', 'Đã xóa vĩnh viễn tài khoản có UID: $uid');
      if(!context.mounted) return;
      GlassToast.show(context, 'Đã xóa tài khoản thành công!');
      _fetchUsers();
    } catch (e) {
      if(!context.mounted) return;
      GlassToast.show(context, 'Lỗi hệ thống: Không thể xóa!', isError: true);
    }
  }

  Future<void> _importCSV(bool isStaffTab) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result != null && result.files.single.bytes != null) {
        setState(() => _isLoading = true);
        final bytes = result.files.single.bytes!;
        final csvString = utf8.decode(bytes); 
        final lines = csvString.split('\n');
        int successCount = 0;
        final roleAssign = isStaffTab ? 'staff' : 'student';

        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = line.split(',');
          if (cols.length >= 3) {
            String email = _formatEmail(cols[2]);
            try {
              final authRes = await Supabase.instance.client.auth.admin.createUser(AdminUserAttributes(email: email, password: '123456', emailConfirm: true));
              final uid = authRes.user!.id;
              await Supabase.instance.client.from('users').insert({
                'uid': uid, 'name': cols[0].trim(), 'studentId': cols[1].trim(), 'email': email,
                'role': roleAssign, 'faculty': cols.length >= 4 ? cols[3].trim() : '', 'major': cols.length >= 5 ? cols[4].trim() : '',
              });
              successCount++;
            } catch (_) { continue; } 
          }
        }
        setState(() => _isLoading = false);
        if(!context.mounted) return;
        GlassToast.show(context, 'Đã tạo thành công $successCount tài khoản!');
        await DbService().logAudit('CREATE', 'Nhập CSV', 'Đã tạo hàng loạt $successCount tài khoản mới bằng file CSV.');
        _fetchUsers(); 
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if(!context.mounted) return;
      GlassToast.show(context, 'Lỗi đọc file: $e', isError: true);
    }
  }

  void _showUserDialog({Map<String, dynamic>? user, required bool isStaffTab}) {
    final isEditing = user != null;
    final nameCtrl = TextEditingController(text: isEditing ? user['name'] : '');
    final idCtrl = TextEditingController(text: isEditing ? user['studentId'] : '');
    final emailCtrl = TextEditingController(text: isEditing ? user['email'] : '');
    final phoneCtrl = TextEditingController(text: isEditing ? user['phone'] : '');
    final dobCtrl = TextEditingController(text: isEditing ? user['dob'] : '');
    final classCtrl = TextEditingController(text: isEditing ? user['className'] : '');
    final idcardCtrl = TextEditingController(text: isEditing ? user['idcard'] : '');
    final addressCtrl = TextEditingController(text: isEditing ? user['address'] : '');

    // HÀM MỞ LỊCH ĐỘNG
    Future<void> selectDate(BuildContext dialogContext) async {
      final DateTime? picked = await showDatePicker(
        context: dialogContext,
        initialDate: DateTime(2005, 1, 1), // Ngày gợi ý mặc định
        firstDate: DateTime(1980, 1, 1),   // Giới hạn năm xa nhất
        lastDate: DateTime.now(),          // Không được chọn ngày tương lai
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF1E3A8A), // Màu Navy chủ đạo của Admin
                onPrimary: Colors.white,
                onSurface: AppColors.gray900,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        // Định dạng ngày thành dạng DD/MM/YYYY chuẩn hóa để lưu DB
        dobCtrl.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      }
    }
    
    bool isProcessing = false;

    // FIX YÊU CẦU 5: TẠO CÁC BIẾN CHO COMBOBOX (DROPDOWN)
    final List<String> genders = ['Nam', 'Nữ', 'Khác'];
    final List<String> faculties = ['Khoa Công nghệ thông tin', 'Khoa Tài chính - Kế toán', 'Khoa Quản trị kinh doanh', 'Khoa Ngoại ngữ', 'Khoa Du lịch & Ẩm thực', 'Khác'];
    final List<String> majors = ['Công nghệ thông tin', 'Kỹ thuật phần mềm', 'An toàn thông tin', 'Khoa học dữ liệu', 'Kế toán', 'Quản trị kinh doanh', 'Khác'];
    
    String selectedGender = isEditing && genders.contains(user['gender']) ? user['gender'] : 'Nam';
    String selectedFaculty = isEditing && user['faculty'] != null && user['faculty'].toString().isNotEmpty ? user['faculty'] : 'Khoa Công nghệ thông tin';
    String selectedMajor = isEditing && user['major'] != null && user['major'].toString().isNotEmpty ? user['major'] : 'Công nghệ thông tin';

    if (!faculties.contains(selectedFaculty)) faculties.add(selectedFaculty);
    if (!majors.contains(selectedMajor)) majors.add(selectedMajor);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 800, padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? 'Sửa Thông tin' : (isStaffTab ? 'Thêm Cán bộ' : 'Thêm Sinh viên'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Họ và tên *'), TextField(controller: nameCtrl, decoration: _inputDeco('Nhập họ tên...'))])),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel(isStaffTab ? 'Mã Cán bộ *' : 'Mã Sinh viên *'), 
                          TextField(
                            controller: idCtrl, decoration: _inputDeco('Nhập mã...'),
                            onChanged: (val) { if (!isEditing && !isStaffTab) emailCtrl.text = val.trim().isNotEmpty ? '${val.trim()}@hdpe.edu.vn' : ''; }
                          )
                        ])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Email * (Mật khẩu mặc định: 123456)'), TextField(controller: emailCtrl, enabled: isStaffTab && !isEditing, decoration: _inputDeco(isEditing ? 'Không thể sửa email' : (isStaffTab ? 'Nhập email (Vd: cb)' : 'Tự động tạo từ Mã SV')))])),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Số điện thoại'), TextField(controller: phoneCtrl, decoration: _inputDeco('09...'))])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // COMBOBOX GIỚI TÍNH
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel('Giới tính'), 
                          DropdownButtonFormField<String>(
                            value: selectedGender, decoration: _inputDeco('Chọn'),
                            items: genders.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setDialogState(() => selectedGender = val!),
                          )
                        ])),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            children: [
                              _buildInputLabel('Ngày sinh'), 
                              TextField(
                                controller: dobCtrl,
                                readOnly: true, // 🔒 KHÓA KHÔNG CHO GÕ TAY, TRÁNH LỖI ĐỊNH DẠNG
                                onTap: () => selectDate(context), // Click vào là bung bảng lịch
                                decoration: InputDecoration(
                                  hintText: 'Chọn ngày...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  suffixIcon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF1E3A8A), size: 20), // Icon cuốn lịch Navy
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
                                ),
                              )
                            ]
                          )
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Số CCCD'), TextField(controller: idcardCtrl, decoration: _inputDeco('Nhập số CCCD...'))])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // COMBOBOX KHOA VÀ CHUYÊN NGÀNH
                        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel('Khoa / Đơn vị'), 
                          DropdownButtonFormField<String>(
                            value: selectedFaculty, decoration: _inputDeco('Chọn Khoa'), isExpanded: true,
                            items: faculties.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setDialogState(() => selectedFaculty = val!),
                          )
                        ])),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildInputLabel('Chuyên ngành'), 
                          DropdownButtonFormField<String>(
                            value: selectedMajor, decoration: _inputDeco('Chọn Ngành'), isExpanded: true,
                            items: majors.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setDialogState(() => selectedMajor = val!),
                          )
                        ])),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Lớp sinh hoạt'), TextField(controller: classCtrl, decoration: _inputDeco('12DHTH...'))])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel('Địa chỉ liên hệ'), TextField(controller: addressCtrl, decoration: _inputDeco('Nhập địa chỉ đầy đủ...'))]),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: isProcessing ? null : () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: AppColors.gray500))), const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: isProcessing ? null : () async {
                            if (nameCtrl.text.trim().isEmpty || idCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                              GlassToast.show(context, 'Vui lòng điền các trường có dấu *', isError: true); return;
                            }
                            setDialogState(() => isProcessing = true);
                            try {
                              final String finalEmail = _formatEmail(emailCtrl.text);
                              
                              final data = {
                                'name': nameCtrl.text.trim(), 'studentId': idCtrl.text.trim(), 'phone': phoneCtrl.text.trim(),
                                'gender': selectedGender, 'dob': dobCtrl.text.trim(), 'className': classCtrl.text.trim(), // Lưu biến Combobox
                                'idCard': idcardCtrl.text.trim(), 'address': addressCtrl.text.trim(), 
                                'faculty': selectedFaculty, 'major': selectedMajor, // Lưu biến Combobox
                                'role': isStaffTab ? 'staff' : 'student',
                              };
                              
                              if (isEditing) {
                                await Supabase.instance.client.from('users').update(data).eq('uid', user['uid']);
                              } else {
                                final authRes = await Supabase.instance.client.auth.admin.createUser(AdminUserAttributes(email: finalEmail, password: '123456', emailConfirm: true));
                                final uid = authRes.user!.id;
                                data['uid'] = uid; data['email'] = finalEmail;
                                await Supabase.instance.client.from('users').insert(data);
                              }
                              await DbService().logAudit(isEditing ? 'UPDATE' : 'CREATE', 'Tài khoản User', 'Đã ${isEditing ? 'cập nhật' : 'tạo mới'} thông tin cho: ${nameCtrl.text.trim()}');
                              
                              if (!context.mounted) return;
                              Navigator.pop(context); _fetchUsers(); GlassToast.show(context, 'Lưu dữ liệu thành công!');
                            } catch (e) {
                              setDialogState(() => isProcessing = false);
                              if (!context.mounted) return; GlassToast.show(context, 'Lỗi: Kiểm tra Service Key. Chi tiết: $e', isError: true); 
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : Text(isEditing ? 'Cập nhật' : 'Tạo tài khoản', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        }
      )
    );
  }

  Widget _buildInputLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)));
  InputDecoration _inputDeco(String hint) => InputDecoration(hintText: hint, filled: true, fillColor: AppColors.gray100, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A8A))));

  @override
  Widget build(BuildContext context) {
    final students = _allUsers.where((e) => (e['role']?.toString().toLowerCase() == 'student') && ((e['name'] ?? '').toString().toLowerCase().contains(_searchTerm.toLowerCase()) || (e['studentId'] ?? '').toString().toLowerCase().contains(_searchTerm.toLowerCase()))).toList();
    final staffs = _allUsers.where((e) => (e['role']?.toString().toLowerCase() == 'staff' || e['role']?.toString().toLowerCase() == 'admin') && ((e['name'] ?? '').toString().toLowerCase().contains(_searchTerm.toLowerCase()) || (e['studentId'] ?? '').toString().toLowerCase().contains(_searchTerm.toLowerCase()))).toList();

    return _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))) : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
          // FIX UI BẰNG WRAP CHO HEADER
          child: Wrap(
            spacing: 16, runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Quản lý Người dùng', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gray900)), SizedBox(height: 6), Text('Mật khẩu mặc định khi tạo tài khoản là: 123456', style: TextStyle(color: AppColors.gray500))]),
              SizedBox(width: 300, child: TextField(onChanged: (val) => setState(() => _searchTerm = val), decoration: _inputDeco('Tìm tên hoặc mã...').copyWith(prefixIcon: const Icon(Icons.search_rounded), fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)))))
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3A8A), unselectedLabelColor: AppColors.gray500, indicatorColor: const Color(0xFF1E3A8A), indicatorWeight: 3,
          tabs: const [Tab(text: '👤 Tài khoản Sinh viên'), Tab(text: '💼 Tài khoản Cán bộ & Admin')],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [ _buildUserList(students, isStaffTab: false), _buildUserList(staffs, isStaffTab: true) ],
          ),
        )
      ],
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> list, {required bool isStaffTab}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Wrap(
            spacing: 12, runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(onPressed: () => _importCSV(isStaffTab), icon: const Icon(Icons.upload_file_rounded, color: Color(0xFF1E3A8A)), label: const Text('Nhập CSV', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: Color(0xFF1E3A8A)))),
              ElevatedButton.icon(onPressed: () => _showUserDialog(isStaffTab: isStaffTab), icon: const Icon(Icons.add_rounded, color: Colors.white), label: Text(isStaffTab ? 'Thêm Cán bộ' : 'Thêm Sinh viên', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty 
            ? const Center(child: Text('Không tìm thấy dữ liệu', style: TextStyle(color: AppColors.gray500)))
            // FIX UI BẰNG CÁCH BỌC CUỘN NGANG CHO LISTVIEW
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: constraints.maxWidth > 1100 ? constraints.maxWidth : 1100, // Chiều rộng tối thiểu
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 32), itemCount: list.length,
                        itemBuilder: (context, index) {
                          final user = list[index];
                          final role = user['role'].toString().toLowerCase();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gray200)),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 22, backgroundColor: role == 'admin' ? AppColors.danger.withValues(alpha: 0.1) : const Color(0xFF1E3A8A).withValues(alpha: 0.1), child: Text(user['name']?.toString().substring(0,1).toUpperCase() ?? 'U', style: TextStyle(color: role == 'admin' ? AppColors.danger : const Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16))),
                                const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user['name'] ?? 'Vô danh', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text('${user['studentId'] ?? 'Không mã'} • ${user['email']}', style: const TextStyle(color: AppColors.gray500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)])),
                                TextButton.icon(onPressed: () => _resetPassword(user['uid'], user['name']), icon: const Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.warning), label: const Text('Reset Pass', style: TextStyle(color: AppColors.warning))),
                                IconButton(icon: const Icon(Icons.edit_rounded, color: AppColors.gray500), tooltip: 'Sửa', onPressed: () => _showUserDialog(user: user, isStaffTab: isStaffTab)),
                                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), tooltip: 'Xóa', onPressed: () => _deleteUser(user['uid'])),
                              ],
                            ),
                          );
                        }
                      ),
                    ),
                  );
                }
              ),
        ),
      ],
    );
  }
}