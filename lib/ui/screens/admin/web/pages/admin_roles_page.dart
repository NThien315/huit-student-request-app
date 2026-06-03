import 'package:flutter/material.dart';
import '../admin_web_data.dart';
import '../admin_web_models.dart';
import '../widgets/admin_common.dart';

class AdminRolesPage extends StatefulWidget {
  const AdminRolesPage({super.key});

  @override
  State<AdminRolesPage> createState() => _AdminRolesPageState();
}

class _AdminRolesPageState extends State<AdminRolesPage> {
  final name = TextEditingController();
  final code = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController(text: 'KhoaCNTT2026@');

  void addStaff() {
    if (name.text.trim().isEmpty || code.text.trim().isEmpty || email.text.trim().isEmpty) return;

    setState(() {
      AdminMockData.staffs.add(
        StaffAccount(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name.text.trim(),
          code: code.text.trim(),
          email: email.text.trim(),
          role: 'Giáo vụ',
        ),
      );
      name.clear();
      code.clear();
      email.clear();
      password.text = 'KhoaCNTT2026@';
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo tài khoản thành công')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Phân quyền & Tài khoản',
            subtitle: 'Quản lý tài khoản cán bộ giáo vụ và quyền truy cập hệ thống',
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: WhiteBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Danh sách tài khoản cán bộ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      Column(
                        children: AdminMockData.staffs.map((e) {
                          return _StaffCard(
                            data: e,
                            onToggleLock: () => setState(() => e.locked = !e.locked),
                            onDelete: () => setState(() => AdminMockData.staffs.remove(e)),
                          );
                        }).toList(),
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
                      const Text('Tạo tài khoản nhanh', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 20),
                      InputBox(label: 'Họ và tên giáo vụ', controller: name),
                      InputBox(label: 'Mã giáo vụ', controller: code),
                      InputBox(label: 'Email công tác', controller: email),
                      InputBox(label: 'Mật khẩu mặc định', controller: password),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminColors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: addStaff,
                          icon: const Icon(Icons.check_rounded, color: Colors.white),
                          label: const Text('Tạo tài khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
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
}

class _StaffCard extends StatelessWidget {
  final StaffAccount data;
  final VoidCallback onToggleLock;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.data,
    required this.onToggleLock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final locked = data.locked;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: locked ? const Color(0xfffff1f2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: locked ? const Color(0xfffca5a5) : const Color(0xffbfdbfe), width: 1.4),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: locked ? const Color(0xffffdddd) : const Color(0xffeff6ff),
            child: Text(
              data.name.split(' ').last[0],
              style: TextStyle(color: locked ? AdminColors.red : AdminColors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('Mã GV: ${data.code}\n${data.email}', style: const TextStyle(color: AdminColors.muted)),
              ],
            ),
          ),
          SmallTag(text: locked ? 'Đã khóa' : 'Hoạt động', color: locked ? AdminColors.red : AdminColors.green),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onToggleLock,
            icon: Icon(locked ? Icons.lock_open_rounded : Icons.lock_rounded),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AdminColors.red,
          ),
        ],
      ),
    );
  }
}
