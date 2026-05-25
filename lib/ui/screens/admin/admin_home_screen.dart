import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int index = 0;

  final pages = const [
    CreateAccountScreen(),
    SendNotificationScreen(),
    DataMaintenanceScreen(),
    NotificationHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (value) => setState(() => index = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Tài khoản',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.storage), label: 'Dữ liệu'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        ],
      ),
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController(text: 'khoaCNTT2026@');

  void showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo tài khoản thành công'),
        content: const Text(
          'Thông tin đăng nhập đã được gửi đến email giáo vụ. '
          'Giáo vụ có thể đăng nhập trên ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại danh sách'),
          ),
          ElevatedButton(
            onPressed: () {
              nameController.clear();
              idController.clear();
              emailController.clear();
              passController.text = 'khoaCNTT2026@';
              Navigator.pop(context);
            },
            child: const Text('Tạo thêm tài khoản'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Cấp tài khoản mới',
      child: Column(
        children: [
          AdminTextField(
            label: 'Họ và tên giáo vụ *',
            controller: nameController,
          ),
          AdminTextField(label: 'Mã giáo vụ ID *', controller: idController),
          AdminTextField(
            label: 'Email công tác *',
            controller: emailController,
          ),
          AdminTextField(
            label: 'Mật khẩu mặc định',
            controller: passController,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: showSuccess,
              child: const Text('Tạo tài khoản'),
            ),
          ),
        ],
      ),
    );
  }
}

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  String receiver = 'Tất cả người dùng';
  bool push = true;
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  void showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            const Text(
              'Phát thông báo thành công',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                titleController.clear();
                contentController.clear();
                Navigator.pop(context);
              },
              child: const Text('Tạo thông báo mới'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Gửi thông báo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đối tượng nhận thông báo',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          RadioListTile(
            value: 'Tất cả người dùng',
            groupValue: receiver,
            onChanged: (v) => setState(() => receiver = v!),
            title: const Text('Tất cả người dùng sinh viên, giảng viên'),
          ),
          RadioListTile(
            value: 'Chỉ sinh viên',
            groupValue: receiver,
            onChanged: (v) => setState(() => receiver = v!),
            title: const Text('Chỉ sinh viên'),
          ),
          RadioListTile(
            value: 'Chỉ giáo vụ khoa',
            groupValue: receiver,
            onChanged: (v) => setState(() => receiver = v!),
            title: const Text('Chỉ giáo vụ khoa'),
          ),
          AdminTextField(
            label: 'Tiêu đề thông báo',
            controller: titleController,
          ),
          AdminTextField(
            label: 'Nội dung chi tiết',
            controller: contentController,
            maxLines: 4,
          ),
          SwitchListTile(
            value: push,
            onChanged: (v) => setState(() => push = v),
            title: const Text('Đẩy kèm Push Notification'),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: showSuccess,
              child: const Text('Phát Thông Báo'),
            ),
          ),
        ],
      ),
    );
  }
}

class DataMaintenanceScreen extends StatelessWidget {
  const DataMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Dữ liệu và bảo trì',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xff111827),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TÌNH TRẠNG DATABASE',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 8),
                Text(
                  'HOẠT ĐỘNG TỐT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dung lượng lưu trữ\n1,478 / 5 TB',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Bản ghi phúc khảo\n12,586',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AdminCard(
            icon: Icons.backup,
            title: 'Sao lưu dữ liệu',
            subtitle: 'Tạo bản sao lưu toàn bộ thông tin yêu cầu và tài khoản.',
            buttonText: 'Tạo bản sao lưu mới',
          ),
          const SizedBox(height: 12),
          AdminCard(
            icon: Icons.cleaning_services,
            title: 'Dọn dẹp hệ thống',
            subtitle: 'Xóa cache và dữ liệu tạm, xóa log cũ hơn 30 ngày.',
            buttonText: 'Dọn dẹp',
          ),
        ],
      ),
    );
  }
}

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Lịch sử thông báo',
      child: Column(
        children: const [
          TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm kiếm',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          NotificationItem(
            title: 'Lịch nghỉ lễ 30/4 - 1/5',
            status: 'Đã gửi',
            content: 'Phòng đào tạo thông báo nghỉ lễ các ngày...',
            receiver: 'Tất cả người dùng',
            views: '1,881 đã xem',
          ),
          NotificationItem(
            title: 'Bảo trì server nộp đơn',
            status: 'Hẹn giờ',
            content: 'Phòng đào tạo thông báo nghỉ bảo trì hệ thống...',
            receiver: 'Chỉ giáo vụ',
            views: '210 đã xem',
          ),
        ],
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  final String title;
  final Widget child;

  const AdminPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class AdminTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const AdminTextField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xffF3F6FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;

  const AdminCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: Text(buttonText)),
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String title;
  final String status;
  final String content;
  final String receiver;
  final String views;

  const NotificationItem({
    super.key,
    required this.title,
    required this.status,
    required this.content,
    required this.receiver,
    required this.views,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(status, style: const TextStyle(color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(receiver),
              Text(views, style: const TextStyle(color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }
}
