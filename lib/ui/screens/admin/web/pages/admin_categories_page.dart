import 'package:flutter/material.dart';
import '../admin_web_data.dart';
import '../admin_web_models.dart';
import '../widgets/admin_common.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final list = AdminMockData.categories
        .where((e) => e.name.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Quản lý Danh mục',
                  subtitle: 'Đang quản lý các loại đơn từ hệ thống học vụ',
                ),
              ),
              SizedBox(width: 320, child: SearchBox(hint: 'Tìm kiếm danh mục...', onChanged: (value) => setState(() => search = value))),
              const SizedBox(width: 16),
              BlueButton(
                text: 'Thêm loại đơn',
                icon: Icons.add_rounded,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _AddCategoryDialog(onAdded: () => setState(() {})),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Column(
            children: list.map((e) {
              return _CategoryListItem(
                data: e,
                onChanged: (value) => setState(() => e.active = value),
                onDelete: () => setState(() => AdminMockData.categories.remove(e)),
                onEdit: () => showDialog(
                  context: context,
                  builder: (_) => _EditCategoryDialog(data: e, onUpdated: () => setState(() {})),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryListItem extends StatelessWidget {
  final RequestCategory data;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _CategoryListItem({
    required this.data,
    required this.onChanged,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final active = data.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? const Color(0xffbfdbfe) : AdminColors.border, width: active ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(color: const Color(0xffeff6ff), borderRadius: BorderRadius.circular(12)),
            child: Icon(active ? Icons.article_rounded : Icons.assignment_rounded, color: active ? AdminColors.blue : AdminColors.muted),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text(data.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AdminColors.text)),
                    SmallTag(text: data.department, color: const Color(0xffd946ef)),
                    SmallTag(text: active ? 'Hoạt động' : 'Tạm ngưng', color: active ? AdminColors.green : AdminColors.muted),
                  ],
                ),
                const SizedBox(height: 8),
                Text(data.description, style: const TextStyle(color: AdminColors.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: AdminColors.bg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Text('Hạn xử lý', style: TextStyle(fontSize: 12, color: AdminColors.muted)),
                const SizedBox(height: 2),
                Text('⏱ ${data.processingTime}', style: const TextStyle(fontWeight: FontWeight.w900, color: AdminColors.text)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Switch(value: active, activeColor: AdminColors.blue, onChanged: onChanged),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded), color: AdminColors.muted),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded), color: AdminColors.red),
        ],
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  final VoidCallback onAdded;

  const _AddCategoryDialog({required this.onAdded});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final name = TextEditingController();
  final desc = TextEditingController();
  final dept = TextEditingController(text: 'Phòng CTSV');
  final time = TextEditingController(text: '1-3 ngày');

  void save() {
    if (name.text.trim().isEmpty) return;

    AdminMockData.categories.add(
      RequestCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.text.trim(),
        description: desc.text.trim().isEmpty ? 'Đang cập nhật mô tả' : desc.text.trim(),
        department: dept.text.trim(),
        processingTime: time.text.trim(),
        active: true,
      ),
    );

    widget.onAdded();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm loại đơn mới'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputBox(label: 'Tên loại đơn', controller: name),
            InputBox(label: 'Phòng ban xử lý', controller: dept),
            InputBox(label: 'Mô tả hướng dẫn', controller: desc, maxLines: 4),
            InputBox(label: 'Thời gian xử lý', controller: time),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: save, child: const Text('Lưu danh mục')),
      ],
    );
  }
}

class _EditCategoryDialog extends StatefulWidget {
  final RequestCategory data;
  final VoidCallback onUpdated;

  const _EditCategoryDialog({
    required this.data,
    required this.onUpdated,
  });

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  late final TextEditingController name;
  late final TextEditingController desc;
  late final TextEditingController dept;
  late final TextEditingController time;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.data.name);
    desc = TextEditingController(text: widget.data.description);
    dept = TextEditingController(text: widget.data.department);
    time = TextEditingController(text: widget.data.processingTime);
  }

  void save() {
    widget.data.name = name.text;
    widget.data.description = desc.text;
    widget.data.department = dept.text;
    widget.data.processingTime = time.text;
    widget.onUpdated();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sửa danh mục'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InputBox(label: 'Tên loại đơn', controller: name),
            InputBox(label: 'Phòng ban xử lý', controller: dept),
            InputBox(label: 'Mô tả hướng dẫn', controller: desc, maxLines: 4),
            InputBox(label: 'Thời gian xử lý', controller: time),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: save, child: const Text('Lưu thay đổi')),
      ],
    );
  }
}
