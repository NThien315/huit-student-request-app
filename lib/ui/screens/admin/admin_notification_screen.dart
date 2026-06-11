import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../widgets/glass_toast.dart';
import '../../../services/db_service.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});
  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _isSending = false;

  Future<void> _sendGlobalNotification() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      GlassToast.show(context, 'Vui lòng nhập Tiêu đề và Nội dung!', isError: true); return;
    }
    setState(() => _isSending = true);
    
    try {
      // 1. Kéo toàn bộ UID của sinh viên về
      final users = await Supabase.instance.client.from('users').select('uid').eq('role', 'student');
      
      // 2. Tạo mảng thông báo để Insert hàng loạt
      List<Map<String, dynamic>> notifs = [];
      for (var u in users) {
        notifs.add({
          'student_uid': u['uid'],
          'title': '📢 THÔNG BÁO TỪ TRƯỜNG: ${_titleCtrl.text.trim()}',
          'body': _bodyCtrl.text.trim(),
          'request_id': null, // Báo đây là tin tức chung
          'is_read': false,
          'created_at': DateTime.now().toUtc().toIso8601String()
        });
      }

      // Đẩy mẻ 500 thông báo một lúc nếu trường quá đông để tránh nghẽn
      for (var i = 0; i < notifs.length; i += 500) {
        int end = (i + 500 < notifs.length) ? i + 500 : notifs.length;
        await Supabase.instance.client.from('notifications').insert(notifs.sublist(i, end));
      }

      await DbService().logAudit('CREATE', 'Thông báo Toàn trường', 'Đã phát thanh thông báo: ${_titleCtrl.text.trim()} đến ${notifs.length} sinh viên.');

      if (mounted) {
        GlassToast.show(context, 'Đã gửi thông báo thành công đến ${notifs.length} sinh viên!');
        _titleCtrl.clear(); _bodyCtrl.clear();
      }
    } catch (e) {
      if (mounted) GlassToast.show(context, 'Lỗi gửi thông báo', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông báo Toàn trường', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gray900)),
          const SizedBox(height: 6),
          const Text('Phát thanh tin tức, thông báo khẩn cấp đến App Mobile của toàn bộ Sinh viên.', style: TextStyle(color: AppColors.gray500)),
          const SizedBox(height: 32),
          
          Container(
            width: 600, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gray200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tiêu đề thông báo (*)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)), const SizedBox(height: 8),
                TextField(controller: _titleCtrl, decoration: InputDecoration(hintText: 'Vd: Lịch nghỉ Tết Nguyên Đán 2026...', filled: true, fillColor: AppColors.gray100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 20),
                const Text('Nội dung chi tiết (*)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900)), const SizedBox(height: 8),
                TextField(controller: _bodyCtrl, maxLines: 6, decoration: InputDecoration(hintText: 'Nhập nội dung cần thông báo...', filled: true, fillColor: AppColors.gray100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendGlobalNotification, 
                    icon: const Icon(Icons.campaign_rounded, color: Colors.white), label: const Text('Phát thanh Thông báo', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}