// lib/ui/screens/admin/admin_layout.dart
import 'package:flutter/material.dart';
import 'package:huit_student_request_app/ui/screens/admin/admin_audit_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../state/auth_provider.dart';
import '../auth/web_login_screen.dart';

// Import 4 màn hình chuẩn của Admin
import 'admin_dashboard_screen.dart';
import 'admin_category_screen.dart';
import 'admin_user_screen.dart';
import 'admin_request_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  bool _manualCollapsed = false;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminCategoryScreen(),
    const AdminUserScreen(),    
    const AdminRequestScreen(),
    const AdminAuditScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCollapsed = screenWidth < 1100 || _manualCollapsed;
    final currentUser = context.watch<AuthProvider>().currentUser;

    // Admin Theme Color
    const Color adminPrimary = Color(0xFF1E3A8A); // Màu xanh Navy đậm quyền lực

    return Scaffold(
      backgroundColor: AppColors.gray100.withValues(alpha: 0.5),
      body: Row(
        children: [
          // SIDEBAR (Thanh điều hướng)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubic,
            width: isCollapsed ? 90 : 270, height: double.infinity,
            decoration: BoxDecoration(color: adminPrimary, boxShadow: [BoxShadow(color: adminPrimary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(6, 0))]),
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
                                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26)),
                                  if (!isCollapsed) ...[
                                    const SizedBox(width: 14),
                                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HDPE ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19, letterSpacing: 1)), Text('Quản trị tối cao', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600))]),
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
                    child: Column(
                      children: [
                        _HoverMenuItem(index: 0, selectedIndex: _selectedIndex, icon: Icons.dashboard_customize_rounded, label: 'Tổng quan Hệ thống', isCollapsed: isCollapsed, onTap: (idx) => setState(() => _selectedIndex = idx)),
                        _HoverMenuItem(index: 1, selectedIndex: _selectedIndex, icon: Icons.receipt_long_rounded, label: 'Quản lý danh mục', isCollapsed: isCollapsed, onTap: (idx) => setState(() => _selectedIndex = idx)),
                        _HoverMenuItem(index: 2, selectedIndex: _selectedIndex, icon: Icons.folder_special_rounded, label: 'Quản lý Người dùng', isCollapsed: isCollapsed, onTap: (idx) => setState(() => _selectedIndex = idx)),
                        _HoverMenuItem(index: 3, selectedIndex: _selectedIndex, icon: Icons.manage_accounts_rounded, label: 'Giám sát Yêu cầu', isCollapsed: isCollapsed, onTap: (idx) => setState(() => _selectedIndex = idx)),
                        _HoverMenuItem(index: 4, selectedIndex: _selectedIndex, icon: Icons.policy_rounded, label: 'Nhật ký Hệ thống', isCollapsed: isCollapsed, onTap: (idx) => setState(() => _selectedIndex = idx)),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (screenWidth >= 1100) Padding(padding: const EdgeInsets.only(bottom: 16), child: IconButton(icon: Icon(isCollapsed ? Icons.keyboard_double_arrow_right_rounded : Icons.keyboard_double_arrow_left_rounded, color: Colors.white54), onPressed: () => setState(() => _manualCollapsed = !_manualCollapsed))),
                      _buildLogoutButton(context, isCollapsed),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT
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
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label, bool isCollapsed) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), padding: EdgeInsets.symmetric(vertical: 14, horizontal: isCollapsed ? 0 : 16),
          decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Align(
            alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 22),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 14),
                    Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar(dynamic currentUser) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70), 
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), 
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.gray200, width: 1))),
      child: Align(
        alignment: Alignment.centerRight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.shield_rounded, color: AppColors.danger, size: 16), SizedBox(width: 8), Text('Quyền: Admin', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13))])),
              const SizedBox(width: 24), Container(width: 1.5, height: 24, color: AppColors.gray200), const SizedBox(width: 24),
              const CircleAvatar(backgroundColor: Color(0xFF1E3A8A), child: Icon(Icons.person_rounded, color: Colors.white)),
              const SizedBox(width: 14),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(currentUser?.name ?? 'Super Admin', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.gray900), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 2), const Text('Hệ thống Quản trị', style: TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isCollapsed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28, left: 16, right: 16),
      child: InkWell(
        onTap: () async {
          await context.read<AuthProvider>().signOut();
          if (context.mounted) Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const WebLoginScreen()), (route) => false);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: isCollapsed ? 0 : 16), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(12)),
          child: Align(
            alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20), if (!isCollapsed) ...[const SizedBox(width: 14), const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14))]]),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverMenuItem extends StatefulWidget {
  final int index; final int selectedIndex; final IconData icon; final String label; final bool isCollapsed; final Function(int) onTap;
  const _HoverMenuItem({required this.index, required this.selectedIndex, required this.icon, required this.label, required this.isCollapsed, required this.onTap});

  @override
  State<_HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<_HoverMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedIndex == widget.index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: () => widget.onTap(widget.index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), padding: EdgeInsets.symmetric(vertical: 14, horizontal: widget.isCollapsed ? 0 : 16),
            decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.15) : (_isHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent), borderRadius: BorderRadius.circular(12)),
            child: Align(
              alignment: widget.isCollapsed ? Alignment.center : Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: isSelected ? Colors.white : Colors.white60, size: 22),
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 14),
                      Text(widget.label, softWrap: false, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
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
}