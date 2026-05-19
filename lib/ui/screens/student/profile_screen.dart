import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huit_student_request_app/ui/screens/auth/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../state/auth_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import 'personal_info_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifEnabled = true;
  Future<Map<String, dynamic>?>? _userProfileFuture;
  final authUser = AuthService().currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkNotificationStatus();
  }

  // SỬA LỖI LOAD LẠI SUPABASE: Đưa lệnh fetch data vào hàm riêng chỉ chạy 1 lần lúc mở trang
  void _loadUserProfile() {
    if (authUser != null) {
      _userProfileFuture = Supabase.instance.client
          .from('users')
          .select()
          .eq('uid', authUser!.id)
          .maybeSingle();
    }
  }

  // Kiểm tra xem user có đang bật thông báo không (Dựa vào việc có fcm_token hay không)
  Future<void> _checkNotificationStatus() async {
    if (authUser != null) {
      final data = await Supabase.instance.client.from('users').select('fcm_token').eq('uid', authUser!.id).maybeSingle();
      if (mounted) {
        setState(() {
          _notifEnabled = data?['fcm_token'] != null;
        });
      }
    }
  }

  // Xử lý bật/tắt nhận thông báo thực tế dưới Database
  Future<void> _toggleNotification(bool value) async {
    setState(() => _notifEnabled = value);
    if (authUser != null) {
      if (value) {
        // Bật: Xin lại token thiết bị và lưu lên DB
        final token = await NotificationService.getFCMToken();
        await Supabase.instance.client.from('users').update({'fcm_token': token}).eq('uid', authUser!.id);
      } else {
        // Tắt: Xóa token trên DB để hệ thống không gửi tin nữa
        await Supabase.instance.client.from('users').update({'fcm_token': null}).eq('uid', authUser!.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: AppColors.primarySV,
        elevation: 0,
        centerTitle: true,
        title: const Text('Tài khoản', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
      ),
      // Thêm padding bottom 120 để không bị Navbar đè lên
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            // ─── HEADER ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              decoration: const BoxDecoration(
                color: AppColors.primarySV,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _userProfileFuture,
                builder: (context, snapshot) {
                  String displayFullName = 'Đang tải...';
                  String displayStudentId = '...';

                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData && snapshot.data != null) {
                      displayFullName = snapshot.data!['name'] ?? 'Chưa cập nhật';
                      displayStudentId = snapshot.data!['studentId'] ?? 'N/A';
                    } else {
                      displayFullName = 'Chưa tạo hồ sơ';
                    }
                  }

                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.white,
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.lightSV,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/default_avatar.jpg',
                              fit: BoxFit.cover,
                              width: 92,
                              height: 92,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: AppColors.primarySV),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(displayFullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text('MSSV: $displayStudentId', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ─── DANH SÁCH MENU ───
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildFlatMenu('Thông tin cá nhân', Icons.person_outline, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen())).then((_) {
                      // Load lại Header nếu bên kia có update thông tin
                      setState(() => _loadUserProfile());
                    });
                  }),
                  _buildFlatMenu('Quy định học vụ', Icons.school_outlined, () {}),
                  // Đổi tính năng theo yêu cầu
                  _buildFlatMenu('Thông tin ứng dụng', Icons.info_outline, () => _showAppInfoDialog(context), isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined, color: AppColors.primarySV),
                        const SizedBox(width: 16),
                        const Text('Nhận thông báo', style: TextStyle(fontSize: 15, color: AppColors.gray900, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Switch(
                          value: _notifEnabled,
                          activeThumbColor: AppColors.primarySV,
                          onChanged: _toggleNotification, // Gọi hàm toggle có logic DB
                        ),
                      ],
                    ),
                  ),
                  const Divider(indent: 56, height: 1),
                  _buildFlatMenu('Góp ý ứng dụng', Icons.chat_bubble_outline, () {}),
                  _buildFlatMenu('Điều khoản & Chính sách', Icons.shield_outlined, () {}, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ─── NÚT ĐĂNG XUẤT ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('HDPE Student Request v1.0.0', style: TextStyle(color: AppColors.gray500, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatMenu(String title, IconData icon, VoidCallback onTap, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Icon(icon, color: AppColors.primarySV),
          title: Text(title, style: const TextStyle(fontSize: 15, color: AppColors.gray900, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.gray500, size: 20),
          onTap: onTap,
        ),
        if (!isLast) const Divider(indent: 56, height: 1),
      ],
    );
  }

  // ─── POPUP THÔNG TIN ỨNG DỤNG ───
  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.groups_rounded, size: 44, color: AppColors.primarySV),
            SizedBox(height: 12),
            Text('Thông tin ứng dụng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 4),
            Text('Phát triển bởi nhóm HDPE', style: TextStyle(fontSize: 13, color: AppColors.gray500, fontWeight: FontWeight.w500)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thành viên 1: Lê Nhật Thiện
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.lightSV,
                  child: Text('T', style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold)),
                ),
                title: Text('Lê Nhật Thiện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.gray900)),
                subtitle: Text('Trưởng nhóm / Lập trình Frontend Web, App Mobile & Logic hệ thống', style: TextStyle(fontSize: 12)),
              ),
              Divider(height: 16, color: AppColors.gray100),
              
              // Thành viên 2: Võ Xuân Trường
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.warningLight,
                  child: Text('Tr', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                ),
                title: Text('Võ Xuân Trường', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.gray900)),
                subtitle: Text('Thành viên / Quản trị Backend, Cơ sở dữ liệu Supabase & Bảo mật mạng', style: TextStyle(fontSize: 12)),
              ),
              Divider(height: 16, color: AppColors.gray100),
              
              // Thành viên 3: Trần Tiến Hoài Nam
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.successLight,
                  child: Text('N', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                ),
                title: Text('Trần Tiến Hoài Nam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.gray900)),
                subtitle: Text('Thành viên / Phân tích yêu cầu hệ thống & Chủ trì biên soạn báo cáo', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Đóng', style: TextStyle(color: AppColors.primarySV, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  // ─── GIAO DIỆN ĐĂNG XUẤT (MATERIAL 3) ───
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('Đăng xuất tài khoản?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Bạn sẽ không nhận được thông báo tiến độ đơn từ hệ thống nữa.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.grey.shade300)),
                      child: const Text('Hủy', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // 1. Đóng hộp thoại đi trước
                        Navigator.pop(dialogContext);
                        
                        try {
                          // 2. Lấy user hiện tại và xóa Token FCM trên DB để ngừng nhận thông báo
                          final authUser = Supabase.instance.client.auth.currentUser;
                          if (authUser != null) {
                            await Supabase.instance.client
                                .from('users')
                                .update({'fcm_token': null})
                                .eq('uid', authUser.id);
                          }

                          // 3. Xóa phiên đăng nhập ở Supabase và Auth
                          await Supabase.instance.client.auth.signOut();
                          await AuthService().signOut();
                          
                          if (context.mounted) {
                            context.read<AuthProvider>().checkAuthState();
                            
                            // Chuyển thẳng về màn hình Login và xóa sạch lịch sử
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi đăng xuất: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }, 
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySV, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.white))
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}