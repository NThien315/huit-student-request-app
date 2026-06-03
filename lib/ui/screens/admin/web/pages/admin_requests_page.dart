import 'package:flutter/material.dart';
import '../admin_web_data.dart';
import '../admin_web_models.dart';
import '../widgets/admin_common.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  int selectedFilter = 0;
  String search = '';

  final filters = const ['Tất cả đơn', 'Chờ xử lý', 'Đã duyệt', 'Từ chối'];

  @override
  Widget build(BuildContext context) {
    var display = AdminMockData.requests.where((e) {
      final matchFilter = selectedFilter == 0 || e.status == filters[selectedFilter];
      final matchSearch = e.studentName.toLowerCase().contains(search.toLowerCase()) ||
          e.id.toLowerCase().contains(search.toLowerCase()) ||
          e.requestType.toLowerCase().contains(search.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Quản lý Đơn từ',
                  subtitle: 'Quản lý và xét duyệt các yêu cầu học vụ của sinh viên',
                ),
              ),
              SizedBox(
                width: 340,
                child: SearchBox(
                  hint: 'Tìm kiếm tên, mã đơn...',
                  onChanged: (value) => setState(() => search = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            children: List.generate(filters.length, (index) {
              final count = index == 0
                  ? AdminMockData.requests.length
                  : AdminMockData.requests.where((e) => e.status == filters[index]).length;

              return _FilterButton(
                title: filters[index],
                count: count,
                active: selectedFilter == index,
                onTap: () => setState(() => selectedFilter = index),
              );
            }),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: display.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 260,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            itemBuilder: (context, index) {
              return _RequestCard(
                data: display[index],
                onUpdated: () => setState(() {}),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String title;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({
    required this.title,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: active ? AdminColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: active ? AdminColors.blue : AdminColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(color: active ? Colors.white : const Color(0xff475569), fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 10,
              backgroundColor: active ? Colors.white24 : const Color(0xffe2e8f0),
              child: Text('$count', style: TextStyle(fontSize: 11, color: active ? Colors.white : Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final StudentRequest data;
  final VoidCallback onUpdated;

  const _RequestCard({
    required this.data,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = data.status == 'Chờ xử lý'
        ? AdminColors.orange
        : data.status == 'Đã duyệt'
            ? AdminColors.green
            : AdminColors.red;

    final pending = data.status == 'Chờ xử lý';
    final approved = data.status == 'Đã duyệt';

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: approved ? const Color(0xfff0fffb) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: approved ? const Color(0xff6ee7b7) : const Color(0xffeef2f7), width: approved ? 1.5 : 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xffeff6ff),
                child: Text(data.studentName[0], style: const TextStyle(color: AdminColors.blue, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.studentName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AdminColors.text)),
                    const SizedBox(height: 3),
                    Text('Lớp: ${data.studentClass} • ${data.id}', style: const TextStyle(color: AdminColors.muted)),
                  ],
                ),
              ),
              SmallTag(text: data.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 24),
          InfoLine(icon: Icons.description_rounded, text: data.requestType, bold: true),
          const SizedBox(height: 12),
          InfoLine(icon: Icons.calendar_month_rounded, text: 'Nộp ngày: ${data.date}'),
          const Spacer(),
          Container(height: 1, color: AdminColors.border),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: pending
                    ? AdminColors.blue
                    : approved
                        ? const Color(0xffd1fae5)
                        : const Color(0xffffdddd),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => _RequestDialog(data: data, onUpdated: onUpdated),
                );
              },
              icon: Icon(Icons.visibility_rounded, color: pending ? Colors.white : statusColor, size: 18),
              label: Text(
                pending ? 'Xem & Xử lý đơn' : 'Xem chi tiết',
                style: TextStyle(color: pending ? Colors.white : statusColor, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestDialog extends StatefulWidget {
  final StudentRequest data;
  final VoidCallback onUpdated;

  const _RequestDialog({
    required this.data,
    required this.onUpdated,
  });

  @override
  State<_RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<_RequestDialog> {
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    noteController.text = widget.data.note;
  }

  void updateStatus(String status) {
    widget.data.status = status;
    widget.data.note = noteController.text;
    widget.onUpdated();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã cập nhật trạng thái: $status')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Chi tiết đơn ${widget.data.id}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogRow('Sinh viên', widget.data.studentName),
            _DialogRow('Lớp', widget.data.studentClass),
            _DialogRow('Loại đơn', widget.data.requestType),
            _DialogRow('Ngày nộp', widget.data.date),
            _DialogRow('Trạng thái', widget.data.status),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Ghi chú xử lý', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        OutlinedButton(onPressed: () => updateStatus('Từ chối'), child: const Text('Từ chối')),
        ElevatedButton(onPressed: () => updateStatus('Đã duyệt'), child: const Text('Duyệt đơn')),
      ],
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
