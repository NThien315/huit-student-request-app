// lib/ui/screens/staff/staff_layout.dart
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';
import 'teacher_dashboard_screen.dart';

class StaffLayout extends StatefulWidget {
  const StaffLayout({super.key});

  @override
  State<StaffLayout> createState() => _StaffLayoutState();
}

class _StaffLayoutState extends State<StaffLayout> {
  int _selectedIndex = 0;
  bool _isNotificationOpen = false;

  final List<Widget> _screens = [
    const TeacherDashboardScreen(),
    const Center(child: Text('🗂 Màn hình Quản lý & Duyệt Đơn Yêu Cầu (Đang xây dựng...)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray500))),
    const Center(child: Text('📚 [Admin] Quản lý Danh mục Môn học (Đang xây dựng...)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray500))),
    const Center(child: Text('👥 [Admin] Quản lý Tài khoản & Phân quyền (Đang xây dựng...)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray500))),
  ];

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100.withValues(alpha: 0.4),
      body: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 270,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)], 
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1B4B).withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(6, 0), 
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('HDPE CORE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: 0.5)),
                              Text('Hệ thống Cán bộ v1.0', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildSidebarItem(index: 0, icon: Icons.dashboard_rounded, label: 'Tổng quan Thống kê'),
                            _buildSidebarItem(index: 1, icon: Icons.assignment_rounded, label: 'Phê duyệt Đơn từ'),
                            _buildSidebarItem(index: 2, icon: Icons.book_rounded, label: 'Quản lý Môn học'),
                            _buildSidebarItem(index: 3, icon: Icons.manage_accounts_rounded, label: 'Phân quyền User'),
                          ],
                        ),
                      ),
                    ),

                    _buildLogoutButton(context),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    _buildHeaderBar(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: _screens[_selectedIndex],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_isNotificationOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isNotificationOpen = false), // Bấm ra ngoài là tắt Popover
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),

          if (_isNotificationOpen)
            Positioned(
              top: 75,
              right: 80,
              child: _buildNotificationCenterPopover(),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required int index, required IconData icon, required String label}) {
    final isSelected = _selectedIndex == index;
    return _SidebarMenuItem(
      icon: icon,
      label: label,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _isNotificationOpen = false;
        });
      },
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      height: 75,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: 3,
            isActive: _isNotificationOpen,
            onTap: () {
              setState(() => _isNotificationOpen = !_isNotificationOpen);
            },
          ),
          const SizedBox(width: 24),
          Container(width: 1.5, height: 24, color: AppColors.gray200),
          const SizedBox(width: 24),
          
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cán bộ Giáo vụ', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              SizedBox(height: 2),
              Text('Khoa Công nghệ Thông tin', style: TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCenterPopover() {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 460),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray200, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thông báo mới nhận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                Text('Đánh dấu đã đọc', style: TextStyle(fontSize: 12, color: AppColors.primarySV, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.gray200),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildMiniNotifItem('Đơn hủy học phần mới', 'SV Lê Nhật Thiện vừa nộp đơn mới.', '5 phút trước', AppColors.primarySV),
                _buildMiniNotifItem('Yêu cầu hoãn thi y tế', 'SV Võ Xuân Trường bổ sung minh chứng bệnh án.', '1 giờ trước', AppColors.warning),
                _buildMiniNotifItem('Hồ sơ xin thôi học', 'SV Trần Tiến Hoài Nam nộp đơn rút hồ sơ.', '3 giờ trước', AppColors.danger),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.gray200),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            alignment: Alignment.center,
            child: const Text('Xem tất cả thông báo trên hệ thống', style: TextStyle(color: AppColors.gray500, fontSize: 13, fontWeight: FontWeight.w600)),
          )
        ],
      ),
    );
  }

  Widget _buildMiniNotifItem(String title, String desc, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.gray900)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12.5, color: AppColors.gray500)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(fontSize: 11, color: AppColors.gray500, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28, left: 16, right: 16),
      child: InkWell(
        onTap: () async {
          await AuthService().signOut();
          if (context.mounted) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 14),
              Text('Đăng xuất hệ thống', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HOVER SIDEBAR (HIỆU ỨNG TRƯỢT NỔI KHỐI + VIỀN) ───
class _SidebarMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // CHUYỂN MARGIN RA NGOÀI MOUSEREGION ĐỂ KHÔNG BỊ KẸT SỰ KIỆN CHUỘT
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            transform: Matrix4.translationValues(_isHovered && !widget.isSelected ? 6 : 0, 0, 0), 
            decoration: BoxDecoration(
              color: widget.isSelected 
                  ? const Color(0xFF4F46E5) 
                  : (_isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.isSelected ? [
                BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))
              ] : [],
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon, 
                  color: widget.isSelected ? Colors.white : (_isHovered ? const Color(0xFF818CF8) : Colors.white60), 
                  size: 20
                ),
                const SizedBox(width: 14),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected ? Colors.white : (_isHovered ? Colors.white : Colors.white70),
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: (widget.isSelected || _isHovered) ? 1.0 : 0.0,
                  child: const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.white54, size: 16),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final int badgeCount;
  final bool isActive;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.badgeCount, required this.isActive, required this.onTap});

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (widget.isActive || _isHovered) ? AppColors.gray100 : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: (widget.isActive || _isHovered) ? const Color(0xFF4F46E5) : AppColors.gray500, size: 24),
            ),
            if (widget.badgeCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('${widget.badgeCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }
}