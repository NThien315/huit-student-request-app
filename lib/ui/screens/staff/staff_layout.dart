// lib/ui/screens/staff/staff_layout.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/widgets/glass_toast.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../state/auth_provider.dart';
import 'staff_dashboard_screen.dart';
import 'staff_request_screen.dart';
import 'staff_category_screen.dart';
import '../auth/web_login_screen.dart';

class StaffLayout extends StatefulWidget {
  const StaffLayout({super.key});

  @override
  State<StaffLayout> createState() => _StaffLayoutState();
}

class _StaffLayoutState extends State<StaffLayout> {
  int _selectedIndex = 0;
  bool _isNotificationOpen = false;
  bool _manualCollapsed = false;
  
  List<Map<String, dynamic>> _recentPendingRequests = [];

  final List<Widget> _screens = [
    const StaffDashboardScreen(),
    const StaffRequestScreen(),
    const StaffCategoryScreen(),
  ];

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _fetchAvatar();
  }

  // HÀM LẤY ẢNH TỪ DATABASE
  Future<void> _fetchAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client.from('users').select('avatar_url').eq('uid', user.id).maybeSingle();
      if (mounted) setState(() => _avatarUrl = data?['avatar_url']);
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await Supabase.instance.client.from('requests').select().eq('status', 'pending').order('createdAt', ascending: false).limit(5);
      if (mounted) setState(() => _recentPendingRequests = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Lỗi tải thông báo GV: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCollapsed = screenWidth < 1100 || _manualCollapsed;
    final currentUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.gray100.withValues(alpha: 0.5),
      body: Stack(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic,
                width: isCollapsed ? 90 : 270, height: double.infinity,
                decoration: BoxDecoration(color: Colors.white, border: const Border(right: BorderSide(color: AppColors.gray200, width: 1)), boxShadow: [BoxShadow(color: AppColors.gray200.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(6, 0))]),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _selectedIndex = 0),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 30, horizontal: isCollapsed ? 0 : 24),
                              child: Align(
                                alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primarySV.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primarySV.withValues(alpha: 0.2))), child: const Icon(Icons.school_rounded, color: AppColors.primarySV, size: 24)),
                                      if (!isCollapsed) ...[
                                        const SizedBox(width: 14),
                                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HDPE CORE', style: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.w900, fontSize: 19), maxLines: 1, overflow: TextOverflow.clip), Text('Hệ thống Cán bộ', style: TextStyle(color: AppColors.gray500, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.clip)]),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        // CUỘN DỌC TRÁNH TRÀN MENU KHI THU NHỎ
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildSidebarItem(index: 0, icon: Icons.dashboard_rounded, label: 'Tổng quan', isCollapsed: isCollapsed),
                              _buildSidebarItem(index: 1, icon: Icons.assignment_rounded, label: 'Duyệt Yêu cầu', isCollapsed: isCollapsed),
                              _buildSidebarItem(index: 2, icon: Icons.book_rounded, label: 'QL Danh mục', isCollapsed: isCollapsed),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (screenWidth >= 1100) 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16), 
                              child: IconButton(
                                icon: Icon(isCollapsed ? Icons.keyboard_double_arrow_right_rounded : Icons.keyboard_double_arrow_left_rounded, color: AppColors.gray500), 
                                onPressed: () => setState(() => _manualCollapsed = !_manualCollapsed)
                              )
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    _buildHeaderBar(currentUser),
                    Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _screens[_selectedIndex])),
                  ],
                ),
              ),
            ],
          ),
          if (_isNotificationOpen) Positioned.fill(child: GestureDetector(onTap: () => setState(() => _isNotificationOpen = false), behavior: HitTestBehavior.opaque, child: Container(color: Colors.transparent))),
          if (_isNotificationOpen) Positioned(top: 75, right: 80, child: _buildNotificationCenterPopover()),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required int index, required IconData icon, required String label, required bool isCollapsed}) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() { _selectedIndex = index; _isNotificationOpen = false; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), padding: EdgeInsets.symmetric(vertical: 14, horizontal: isCollapsed ? 0 : 16),
            decoration: BoxDecoration(color: isSelected ? AppColors.primarySV.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppColors.primarySV.withValues(alpha: 0.3) : Colors.transparent)),
            child: Align(
              alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: isSelected ? AppColors.primarySV : AppColors.gray500, size: 20),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 14),
                      Text(label, style: TextStyle(color: isSelected ? AppColors.primarySV : AppColors.gray500, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // FIX CANH LỀ PHẢI TUYỆT ĐỐI BẰNG SPACER VÀ POSITION ĐÚNG
  Widget _buildHeaderBar(dynamic currentUser) {
    return Container(
      height: 75, padding: const EdgeInsets.symmetric(horizontal: 24), decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.gray200, width: 1))),
      child: Row(
        children: [
          const Spacer(), // Đẩy mọi thứ sang bên phải
          GestureDetector(
            onTap: () async {
              final result = await FilePicker.pickFiles(type: FileType.image);
              if (result != null && result.files.single.bytes != null) {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) return;
                final path = 'avatars/$userId.jpg'; // Lưu vào thư mục avatars
                
                // Upload dưới dạng mảng byte (hỗ trợ tốt cho trình duyệt Web)
                await Supabase.instance.client.storage.from('attachments').uploadBinary(path, result.files.single.bytes!, fileOptions: const FileOptions(upsert: true));
                final publicUrl = Supabase.instance.client.storage.from('attachments').getPublicUrl(path);
                
                await Supabase.instance.client.from('users').update({'avatar_url': publicUrl}).eq('uid', userId);
                setState(() => _avatarUrl = publicUrl);
                if (context.mounted) GlassToast.show(context, 'Đã cập nhật ảnh đại diện!');
              }
            },
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1E3A8A),
              backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty) ? NetworkImage(_avatarUrl!) : null,
              child: (_avatarUrl == null || _avatarUrl!.isEmpty) ? const Icon(Icons.person_rounded, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(currentUser?.name ?? 'Ban Giáo vụ', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.gray900)), 
              const SizedBox(height: 2), 
              const Text('Nhấn để cài đặt', style: TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)
            ]
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            position: PopupMenuPosition.under, // Hiển thị menu thả xuống ở dưới
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              if (value == 'password') {
                showDialog(context: context, barrierDismissible: false, builder: (_) => const ChangePasswordDialog());
              } else if (value == 'logout') {
                await context.read<AuthProvider>().signOut();
                if (context.mounted) Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const WebLoginScreen()), (route) => false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'password', child: Row(children: [Icon(Icons.lock_reset_rounded, size: 18), SizedBox(width: 10), Text('Đổi mật khẩu')])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18), SizedBox(width: 10), Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))])),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCenterPopover() {  
    return Container(
      width: 380, constraints: const BoxConstraints(maxHeight: 460), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gray200, width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 15))]),
      child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.all(20), child: Text('Yêu cầu mới chờ duyệt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900))),
          Divider(height: 1, color: AppColors.gray200),
          Flexible(
            child: _recentPendingRequests.isEmpty 
              ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Không có đơn mới', style: TextStyle(color: AppColors.gray500))))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _recentPendingRequests.length,
                  itemBuilder: (context, index) {
                    final req = _recentPendingRequests[index];
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: AppColors.warningLight, child: Icon(Icons.assignment, color: AppColors.warning, size: 18)),
                      title: Text(req['categoryName'] ?? 'Đơn mới', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text('${req['studentName']} (${req['studentId']})', style: const TextStyle(fontSize: 12.5)),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () => setState(() { _selectedIndex = 1; _isNotificationOpen = false; }), 
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

}

// FORM ĐỔI MẬT KHẨU TỐI ƯU GIAO DIỆN & THÔNG BÁO LỖI
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  
  bool _obsOld = true; bool _obsNew = true; bool _obsConfirm = true;
  bool _isProcessing = false;

  InputDecoration _deco(String label, bool isObs, VoidCallback toggle) => InputDecoration(
    labelText: label, filled: true, fillColor: AppColors.gray100,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    suffixIcon: IconButton(icon: Icon(isObs ? Icons.visibility_off : Icons.visibility, color: AppColors.gray500), onPressed: toggle),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Đổi Mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _oldPwCtrl, obscureText: _obsOld, decoration: _deco('Mật khẩu hiện tại', _obsOld, () => setState(() => _obsOld = !_obsOld))),
            const SizedBox(height: 16),
            TextField(controller: _newPwCtrl, obscureText: _obsNew, decoration: _deco('Mật khẩu mới (Tối thiểu 6 ký tự)', _obsNew, () => setState(() => _obsNew = !_obsNew))),
            const SizedBox(height: 16),
            TextField(controller: _confirmPwCtrl, obscureText: _obsConfirm, decoration: _deco('Xác nhận mật khẩu mới', _obsConfirm, () => setState(() => _obsConfirm = !_obsConfirm))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isProcessing ? null : () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
          onPressed: _isProcessing ? null : () async {
            if (_newPwCtrl.text != _confirmPwCtrl.text) { GlassToast.show(context, 'Mật khẩu xác nhận không khớp!', isError: true); return; }
            if (_newPwCtrl.text.length < 6) { GlassToast.show(context, 'Mật khẩu mới phải từ 6 ký tự!', isError: true); return; }
            
            setState(() => _isProcessing = true);
            try {
              final client = Supabase.instance.client;
              final email = client.auth.currentUser!.email!;
              await client.auth.signInWithPassword(email: email, password: _oldPwCtrl.text);
              await client.auth.updateUser(UserAttributes(password: _newPwCtrl.text));
              
              if (!context.mounted) return;
              Navigator.pop(context);
              GlassToast.show(context, 'Đổi mật khẩu thành công!');
            } catch (e) {
              setState(() => _isProcessing = false);
              if (!context.mounted) return;
              String errorMsg = 'Lỗi hệ thống!';
              if (e is AuthException) {
                if (e.message.contains('Invalid login credentials')) {
                  errorMsg = 'Mật khẩu hiện tại không chính xác!';
                } else {
                  errorMsg = e.message;
                }
              }
              GlassToast.show(context, errorMsg, isError: true);
            }
          },
          child: _isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}