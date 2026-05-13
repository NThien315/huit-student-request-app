import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'personal_info_screen.dart'; // Màn hình chi tiết thông tin

import 'package:provider/provider.dart';
import '../../../state/auth_provider.dart';
import '../../../services/db_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white, 
        elevation: 0, 
        centerTitle: true, 
        title: const Text('Cá nhân', style: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold))
      ),
      // 🔥 1. Bọc toàn bộ Column trong SingleChildScrollView để màn hình có thể cuộn
      body: SingleChildScrollView( 
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Profile
            Builder(
              builder: (context) {
                final user = context.watch<AuthProvider>().currentUser;
                
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.lightSV,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/default_avatar.jpg',
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                          // 👉 Nếu lỗi không tìm thấy ảnh, hiện icon người dùng thay thế
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 50, color: AppColors.primarySV);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? 'N/A',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MSSV: ${user?.studentId ?? 'N/A'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                );
              }
            ),
            const SizedBox(height: 12),

            // Menu List
            _buildFlatMenu('Thông tin cá nhân', Icons.person_outline, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen()));
            }),
            _buildFlatMenu('Lịch sử yêu cầu', Icons.history, () {}),
            _buildFlatMenu('Quy định học vụ Khoa CNTT', Icons.description_outlined, () {}),
            
            // Row Thông báo với Switch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Text('Thông báo', style: TextStyle(fontSize: 15, color: AppColors.gray900, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Switch(value: _notifEnabled, activeColor: AppColors.primarySV, onChanged: (v) => setState(() => _notifEnabled = v)),
                ],
              ),
            ),
            const Divider(indent: 20, endIndent: 20, height: 1),
            
            _buildFlatMenu('Góp ý ứng dụng', Icons.chat_bubble_outline, () {}),
            _buildFlatMenu('Điều khoản & Chính sách sử dụng', Icons.policy_outlined, () {}),
            
            // 🔥 2. THAY THẾ const Spacer() bằng SizedBox(height: 32)
            const SizedBox(height: 32), 
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primarySV, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            
            // Thêm chút khoảng trống dưới đáy để khi cuộn lên không bị sát mép màn hình
            const SizedBox(height: 40), 
          ],
        ),
      ),
    );
  }

  Widget _buildFlatMenu(String title, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          title: Text(title, style: const TextStyle(fontSize: 15, color: AppColors.gray900, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.gray500),
          onTap: onTap,
        ),
        const Divider(indent: 20, endIndent: 20, height: 1),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi hệ thống không?', textAlign: TextAlign.center),
        actions: [
          Row(
            children: [
              // NÚT HỦY: Chỉ đóng hộp thoại
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext), 
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primarySV), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                  child: const Text('Hủy', style: TextStyle(color: AppColors.primarySV))
                )
              ),
              const SizedBox(width: 12),
              
              // NÚT ĐĂNG XUẤT: Vừa đóng hộp thoại, vừa gọi Firebase
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // 1. Đóng hộp thoại đi trước
                    Navigator.pop(dialogContext);
                    
                    // 2. Gọi Firebase đăng xuất và đánh thức bộ não
                    try {
                      await DbService().signOut();
                      if (context.mounted) {
                        context.read<AuthProvider>().checkAuthState();
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
          )
        ],
      ),
    );
  }
}