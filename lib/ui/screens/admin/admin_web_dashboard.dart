import 'package:flutter/material.dart';

class AdminWebDashboard extends StatelessWidget {
  const AdminWebDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      body: Row(
        children: [
          _Sidebar(),
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bảng điều khiển Admin',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Quản lý yêu cầu sinh viên, danh mục, tài khoản cán bộ và thông báo hệ thống',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.7,
                          children: const [
                            _StatCard(
                              'Tổng yêu cầu',
                              '128',
                              Icons.folder_copy,
                              Colors.blue,
                            ),
                            _StatCard(
                              'Đang xử lý',
                              '34',
                              Icons.timelapse,
                              Colors.orange,
                            ),
                            _StatCard(
                              'Hoàn thành',
                              '86',
                              Icons.check_circle,
                              Colors.green,
                            ),
                            _StatCard(
                              'Cần bổ sung',
                              '8',
                              Icons.warning,
                              Colors.red,
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _CategoryPanel()),
                            const SizedBox(width: 20),
                            Expanded(child: _AccountPanel()),
                          ],
                        ),

                        const SizedBox(height: 28),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _NotificationPanel()),
                            const SizedBox(width: 20),
                            Expanded(child: _SystemLogPanel()),
                          ],
                        ),
                      ],
                    ),
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

class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xff0f172a),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.school, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text(
                'HUIT Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          _MenuItem(Icons.dashboard, 'Tổng quan', true),
          _MenuItem(Icons.category, 'Danh mục yêu cầu', false),
          _MenuItem(Icons.people, 'Tài khoản cán bộ', false),
          _MenuItem(Icons.notifications, 'Gửi thông báo', false),
          _MenuItem(Icons.storage, 'Dữ liệu & bảo trì', false),
          _MenuItem(Icons.history, 'Nhật ký hệ thống', false),
          const Spacer(),
          _MenuItem(Icons.logout, 'Đăng xuất', false),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool active;

  const _MenuItem(this.icon, this.title, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm yêu cầu, sinh viên, cán bộ...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xfff1f5f9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          const Icon(Icons.notifications_none),
          const SizedBox(width: 20),
          const CircleAvatar(child: Text('AD')),
          const SizedBox(width: 10),
          const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle('Quản lý danh mục yêu cầu', Icons.category),
          const SizedBox(height: 16),
          _CategoryRow('Xin cấp bảng điểm', 'Thời gian xử lý: 2-3 ngày', true),
          _CategoryRow('Xác nhận sinh viên', 'Thời gian xử lý: 1-2 ngày', true),
          _CategoryRow('Giấy giới thiệu thực tập', 'Tạm ngưng', false),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Thêm danh mục'),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;

  const _CategoryRow(this.title, this.subtitle, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: active ? Colors.blue : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: active, onChanged: (_) {}),
        ],
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle('Cấp tài khoản cán bộ', Icons.person_add),
          const SizedBox(height: 16),
          _Input('Họ và tên cán bộ'),
          _Input('Mã giáo vụ'),
          _Input('Email công vụ'),
          _Input('Mật khẩu mặc định'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Tạo tài khoản'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle('Gửi thông báo hệ thống', Icons.notifications),
          const SizedBox(height: 16),
          _Input('Tiêu đề thông báo'),
          _Input('Nội dung thông báo', maxLines: 4),
          Row(
            children: [
              Checkbox(value: true, onChanged: (_) {}),
              const Text('Gửi kèm Push Notification'),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Phát thông báo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemLogPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle('Nhật ký hệ thống', Icons.history),
          const SizedBox(height: 16),
          _LogItem(
            'Admin đã khóa tài khoản cán bộ Lê Tiến Văn Anh',
            '10:24 AM',
          ),
          _LogItem(
            'Admin đã tạm ngưng danh mục Giấy giới thiệu thực tập',
            '09:15 AM',
          ),
          _LogItem(
            'Admin đã thay đổi SLA mặc định từ 2 ngày sang 3 ngày',
            'Hôm qua',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa log cũ'),
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final String title;
  final String time;

  const _LogItem(this.title, this.time);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 10, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(time, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String hint;
  final int maxLines;

  const _Input(this.hint, {this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xfff1f5f9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PanelTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;

  const _Box({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
