// lib/ui/screens/student/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/models/notification_model.dart';
import 'package:huit_student_request_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedTab = 0;

  // FIX: Đồng bộ cột is_read theo Database mới
  Future<void> _markAsRead(String notifId) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true}) // Sửa từ isRead -> is_read
        .eq('id', notifId);
  }

  // FIX: Đồng bộ cột student_uid và is_read theo Database mới
  Future<void> _markAllAsRead(String studentUid) async {
    await Supabase.instance.client
        .from('notifications')
        .update({'is_read': true})      // Sửa từ isRead -> is_read
        .eq('student_uid', studentUid)  // Sửa từ studentUid -> student_uid
        .eq('is_read', false);          // Sửa từ isRead -> is_read
  }

  String _formatDateTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}";
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white, 
        elevation: 0, 
        centerTitle: true,
        title: const Text('Thông báo', style: TextStyle(color: AppColors.gray900, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primarySV, size: 22), 
            onPressed: () {
              if (currentUser != null) {
                _markAllAsRead(currentUser.id);
              }
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildSegmentedControl(),
          ),
          
          Expanded(
            child: currentUser == null 
              ? const Center(child: Text('Vui lòng đăng nhập'))
              : StreamBuilder<List<Map<String, dynamic>>>(
                  // FIX STREAM: Lắng nghe và lọc theo cột student_uid và created_at mới
                  stream: Supabase.instance.client
                      .from('notifications')
                      .stream(primaryKey: ['id'])
                      .eq('student_uid', currentUser.id) // Sửa từ studentUid -> student_uid
                      .order('created_at', ascending: false), // Sửa từ createdAt -> created_at
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primarySV));
                    }
                    
                    final List<Map<String, dynamic>> rawData = snapshot.data ?? [];
                    
                    // MAP QUA MODEL: Ép kiểu sang NotificationModel để sử dụng logic phân loại thông minh
                    final List<NotificationModel> allModels = rawData.map((map) => NotificationModel.fromMap(map)).toList();
                    
                    // Lọc theo tab hiện tại
                    final filteredNotifs = _selectedTab == 0 
                        ? allModels 
                        : allModels.where((n) => n.isRead == false).toList();

                    return _buildNotificationList(filteredNotifs);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifs) {
    if (notifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.gray300),
            const SizedBox(height: 12),
            const Text('Không có thông báo nào', style: TextStyle(color: AppColors.gray500, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: notifs.length,
      itemBuilder: (context, index) {
        final notif = notifs[index];
        
        // SỬ DỤNG TRỰC TIẾP TÍNH NĂNG TỰ ĐỘNG CỦA MODEL
        Color color = notif.color;
        IconData icon = notif.icon;
        final bool isUnread = !notif.isRead;

        return GestureDetector(
          onTap: () {
            if (isUnread) _markAsRead(notif.id);
            _showNotificationDetails(context, notif.title, notif.body, icon, color);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isUnread ? color.withValues(alpha: 0.25) : AppColors.gray200, width: isUnread ? 1.5 : 1),
              boxShadow: [
                isUnread 
                  ? BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, spreadRadius: 1, offset: const Offset(0, 6))
                  : BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title, 
                              style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 14.5, color: AppColors.gray900)
                            ),
                          ),
                          if (isUnread) Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(notif.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.gray500, height: 1.4)),
                      const SizedBox(height: 10),
                      Text(_formatDateTime(notif.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.gray500, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationDetails(BuildContext context, String title, String body, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.gray900))),
              ],
            ),
            const SizedBox(height: 18),
            Text(body, style: const TextStyle(fontSize: 14, color: AppColors.gray500, height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gray100, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Đóng', style: TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(14)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth / 2; 
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _selectedTab * width,
                top: 0, bottom: 0, width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildTabItem(0, 'Tất cả'),
                  _buildTabItem(1, 'Chưa đọc'),
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
        onTap: () => setState(() => _selectedTab = index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? AppColors.primarySV : AppColors.gray500)),
        ),
      ),
    );
  }
}