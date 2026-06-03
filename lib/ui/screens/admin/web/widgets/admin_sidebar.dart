import 'package:flutter/material.dart';
import 'admin_common.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
      child: Column(
        children: [
          const _LogoHeader(),
          const SizedBox(height: 42),
          _SidebarItem(
            index: 0,
            selectedIndex: selectedIndex,
            icon: Icons.grid_view_rounded,
            title: 'Tổng quan',
            onTap: onChanged,
          ),
          _SidebarItem(
            index: 1,
            selectedIndex: selectedIndex,
            icon: Icons.assignment_rounded,
            title: 'Duyệt Đơn từ',
            onTap: onChanged,
          ),
          _SidebarItem(
            index: 2,
            selectedIndex: selectedIndex,
            icon: Icons.book_rounded,
            title: 'QL Môn học',
            onTap: onChanged,
          ),
          _SidebarItem(
            index: 3,
            selectedIndex: selectedIndex,
            icon: Icons.admin_panel_settings_rounded,
            title: 'Phân quyền',
            onTap: onChanged,
          ),
          _SidebarItem(
            index: 4,
            selectedIndex: selectedIndex,
            icon: Icons.storage_rounded,
            title: 'Bảo trì',
            onTap: onChanged,
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
            color: AdminColors.muted,
          ),
          const SizedBox(height: 18),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xffffeeee),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: AdminColors.red),
                SizedBox(width: 10),
                Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: AdminColors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: const Color(0xffeff6ff),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffdbeafe)),
          ),
          child: const Icon(Icons.school_rounded, color: AdminColors.blue, size: 28),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HDPE CORE',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AdminColors.text,
              ),
            ),
            SizedBox(height: 2),
            Text('Hệ thống Cán bộ', style: TextStyle(fontSize: 14, color: AdminColors.muted)),
          ],
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final String title;
  final ValueChanged<int> onTap;

  const _SidebarItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == selectedIndex;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 58,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: active ? const Color(0xffeaf2ff) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xffbfdbfe) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? AdminColors.blue : AdminColors.muted, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? AdminColors.blue : AdminColors.muted,
                ),
              ),
            ),
            if (active) const Icon(Icons.chevron_right_rounded, color: AdminColors.blue),
          ],
        ),
      ),
    );
  }
}
