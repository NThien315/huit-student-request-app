import 'package:flutter/material.dart';
import '../widgets/admin_common.dart';

class AdminMaintenancePage extends StatelessWidget {
  const AdminMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Dữ liệu & Bảo trì',
            subtitle: 'Theo dõi tình trạng cơ sở dữ liệu, sao lưu và dọn dẹp hệ thống',
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: WhiteBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TÌNH TRẠNG DATABASE', style: TextStyle(color: AdminColors.muted, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, color: AdminColors.green),
                          SizedBox(width: 8),
                          Text('HOẠT ĐỘNG TỐT', style: TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: _DbInfo(label: 'Dung lượng lưu trữ', value: '1.4TB / 5TB')),
                          Expanded(child: _DbInfo(label: 'Bản ghi yêu cầu', value: '12,568')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: WhiteBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Công cụ quản trị', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 18),
                      _ActionButton(
                        icon: Icons.backup_rounded,
                        title: 'Sao lưu dữ liệu',
                        subtitle: 'Tạo bản sao lưu toàn bộ thông tin yêu cầu và tài khoản',
                        color: AdminColors.blue,
                        onTap: () => _showMessage(context, 'Đã tạo bản sao lưu demo'),
                      ),
                      _ActionButton(
                        icon: Icons.cleaning_services_rounded,
                        title: 'Dọn dẹp hệ thống',
                        subtitle: 'Xóa cache và dữ liệu tạm',
                        color: AdminColors.orange,
                        onTap: () => _showMessage(context, 'Đã dọn dẹp hệ thống demo'),
                      ),
                      _ActionButton(
                        icon: Icons.delete_forever_rounded,
                        title: 'Xóa log cũ',
                        subtitle: 'Xóa log quá 30 ngày',
                        color: AdminColors.red,
                        onTap: () => _showMessage(context, 'Đã xóa log demo'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _DbInfo extends StatelessWidget {
  final String label;
  final String value;

  const _DbInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AdminColors.muted)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(.35)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AdminColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
